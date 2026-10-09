// Sentinel WinUpdater — companion updater for Sentinel Browser.
// Checks GitHub releases for a newer tag; downloads and launches the
// setup.exe asset on user approval. Also manages a scheduled task for
// automatic checks (/CreateTask, /RemoveTask).
//
// Usage:
//   Sentinel-WinUpdater.exe            interactive check (dialogs)
//   Sentinel-WinUpdater.exe /Auto      silent unless an update exists
//   Sentinel-WinUpdater.exe /CreateTask   register daily update check
//   Sentinel-WinUpdater.exe /RemoveTask   remove the scheduled task

using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text.RegularExpressions;
using System.Windows.Forms;

[DataContract]
class Release {
    [DataMember(Name = "tag_name")] public string TagName;
    [DataMember(Name = "name")] public string Name;
    [DataMember(Name = "html_url")] public string HtmlUrl;
    [DataMember(Name = "assets")] public Asset[] Assets;
}

[DataContract]
class Asset {
    [DataMember(Name = "name")] public string Name;
    [DataMember(Name = "browser_download_url")] public string Url;
}

static class Updater {
    const string Repo = "snazzyatoms/sentinel-browser";
    const string TaskName = "Sentinel WinUpdater";
    const string ExeName = "Sentinel-WinUpdater.exe";

    static string InstallDir =>
        Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

    [STAThread]
    static int Main(string[] args) {
        string mode = args.Length > 0 ? args[0] : "";
        switch (mode.ToLowerInvariant()) {
            case "/createtask": return CreateTask();
            case "/removetask": return RemoveTask();
            case "/auto":       return Check(quiet: true);
            default:            return Check(quiet: false);
        }
    }

    static Version InstalledVersion() {
        string exe = Path.Combine(InstallDir, "sentinel.exe");
        try {
            var v = FileVersionInfo.GetVersionInfo(exe).FileVersion;
            var m = Regex.Match(v ?? "", @"\d+(\.\d+)+");
            if (m.Success) return new Version(m.Value);
        } catch { }
        return new Version("0.0");
    }

    static int Check(bool quiet) {
        Release rel;
        try {
            rel = FetchLatest();
        } catch (Exception e) {
            if (!quiet)
                MessageBox.Show("Could not check for updates:\n" + e.Message,
                    "Sentinel Updater", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return 1;
        }
        if (rel == null || string.IsNullOrEmpty(rel.TagName)) return 1;

        Version latest = ParseTag(rel.TagName);
        if (latest == null || latest <= InstalledVersion()) {
            if (!quiet)
                MessageBox.Show("Sentinel is up to date.",
                    "Sentinel Updater", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return 0;
        }

        string download = FindSetupAsset(rel);
        string label = rel.TagName.TrimStart('v', 'V');
        var r = MessageBox.Show(
            "A new version of Sentinel is available: " + label +
            "\nInstalled: " + InstalledVersion() +
            "\n\nDownload and install now?",
            "Sentinel Updater", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
        if (r != DialogResult.Yes) return 0;

        if (download == null) {
            Process.Start(rel.HtmlUrl ?? "https://github.com/" + Repo + "/releases");
            return 0;
        }

        string tmp = Path.Combine(Path.GetTempPath(), Path.GetFileName(download));
        try {
            using (var wc = UpdaterClient())
                wc.DownloadFile(download, tmp);
            Process.Start(tmp);
        } catch (Exception e) {
            if (!quiet)
                MessageBox.Show("Download failed:\n" + e.Message,
                    "Sentinel Updater", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
        return 0;
    }

    static WebClient UpdaterClient() {
        var wc = new WebClient();
        wc.Headers["User-Agent"] = "Sentinel-WinUpdater";
        return wc;
    }

    static Release FetchLatest() {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
        var ser = new DataContractJsonSerializer(typeof(Release));
        using (var wc = UpdaterClient())
        using (var s = new MemoryStream(wc.DownloadData(
            "https://api.github.com/repos/" + Repo + "/releases/latest")))
            return (Release)ser.ReadObject(s);
    }

    static Version ParseTag(string tag) {
        var m = Regex.Match(tag.TrimStart('v', 'V'), @"^(\d+(?:\.\d+){1,3})(?:-(\d+))?");
        if (!m.Success) return null;
        var v = new Version(m.Groups[1].Value);
        if (m.Groups[2].Success)   // fold -N release rev into 4th part
            v = new Version(v.Major, v.Minor, Math.Max(v.Build, 0),
                int.Parse(m.Groups[2].Value));
        return v;
    }

    static string FindSetupAsset(Release rel) {
        string fallback = null;
        if (rel.Assets != null)
            foreach (var a in rel.Assets) {
                if (a.Name != null && a.Name.EndsWith("setup.exe")) return a.Url;
                if (a.Name != null && a.Name.EndsWith(".zip")) fallback = a.Url;
            }
        return fallback;
    }

    static int CreateTask() {
        string exe = Path.Combine(InstallDir, ExeName);
        string xml = Path.Combine(Path.GetTempPath(), "sentinel-updater-task.xml");
        File.WriteAllText(xml, TaskXml(exe));
        var p = Process.Start(new ProcessStartInfo {
            FileName = "schtasks.exe",
            Arguments = "/Create /TN \"" + TaskName + "\" /XML \"" + xml + "\" /F",
            UseShellExecute = false,
            CreateNoWindow = true,
        });
        p.WaitForExit();
        return p.ExitCode;
    }

    static int RemoveTask() {
        var p = Process.Start(new ProcessStartInfo {
            FileName = "schtasks.exe",
            Arguments = "/Delete /TN \"" + TaskName + "\" /F",
            UseShellExecute = false,
            CreateNoWindow = true,
        });
        p.WaitForExit();
        return 0;
    }

    static string TaskXml(string exe) {
        return @"<?xml version=""1.0"" encoding=""UTF-16""?>
<Task version=""1.2"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <Triggers>
    <LogonTrigger><Enabled>true</Enabled></LogonTrigger>
    <CalendarTrigger>
      <StartBoundary>2020-01-01T12:00:00</StartBoundary>
      <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal><LogonType>InteractiveToken</LogonType></Principal>
  </Principals>
  <Settings>
    <AllowStartIfOnBatteries>true</AllowStartIfOnBatteries>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
  </Settings>
  <Actions>
    <Exec><Command>" + exe + @"</Command><Arguments>/Auto</Arguments></Exec>
  </Actions>
</Task>";
    }
}
