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
using Microsoft.Win32;

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
            case "/diag":       return Diag();
            default:            return Check(quiet: false);
        }
    }

    static Version InstalledVersion() {
        // The installer records the full "157.0.1-1" tag as DisplayVersion.
        // NSIS writes to the 32-bit view, so check it first.
        foreach (var view in new[] { RegistryView.Registry32, RegistryView.Registry64 }) {
            try {
                using (var hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, view))
                using (var k = hklm.OpenSubKey(
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sentinel Sentinel")) {
                    var v = ParseTag((k?.GetValue("DisplayVersion") as string) ?? "");
                    if (v != null) return v;
                }
            } catch { }
        }
        try {
            string exe = Path.Combine(InstallDir, "sentinel.exe");
            var m = Regex.Match(
                FileVersionInfo.GetVersionInfo(exe).FileVersion ?? "",
                @"\d+(\.\d+)+");
            if (m.Success) return new Version(m.Value);
        } catch { }
        return new Version("0.0");
    }

    static int Diag() {
        string path = Path.Combine(Path.GetTempPath(), "sentinel-updater-diag.txt");
        try {
            var rel = FetchLatest();
            File.WriteAllText(path,
                "installed=" + InstalledVersion() +
                "\nlatest=" + (rel == null ? "null" : rel.TagName) +
                "\nparsed=" + (rel == null ? "null" : (object)(ParseTag(rel.TagName) ?? (object)"null")));
        } catch (Exception e) {
            File.WriteAllText(path, e.ToString());
            return 1;
        }
        return 0;
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

        string download, sums;
        FindSetupAsset(rel, out download, out sums);
        string label = rel.TagName.TrimStart('v', 'V');
        var r = MessageBox.Show(
            "A new version of Sentinel is available: " + label +
            "\nInstalled: " + InstalledVersion() +
            "\n\nDownload and install now?",
            "Sentinel Updater", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
        if (r != DialogResult.Yes) return 0;

        // Only an installer can be auto-run; for archives or missing assets,
        // open the release page and let the user handle it.
        if (download == null || !download.EndsWith("setup.exe")) {
            Process.Start(rel.HtmlUrl ?? "https://github.com/" + Repo + "/releases");
            return 0;
        }

        if (sums == null) {
            // No checksum asset to verify against — don't run an unchecked
            // binary; send the user to the release page instead.
            Process.Start(rel.HtmlUrl ?? "https://github.com/" + Repo + "/releases");
            return 0;
        }

        string tmp = Path.Combine(Path.GetTempPath(), Path.GetFileName(download));
        try {
            using (var wc = UpdaterClient()) {
                wc.DownloadFile(download, tmp);
                string expected = ExpectedHash(wc.DownloadString(sums),
                    Path.GetFileName(download));
                if (expected == null || !expected.Equals(Sha256(tmp),
                        StringComparison.OrdinalIgnoreCase)) {
                    File.Delete(tmp);
                    MessageBox.Show(
                        "Update verification failed (checksum mismatch).\n" +
                        "The download was not installed.",
                        "Sentinel Updater", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return 1;
                }
            }
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

    static void FindSetupAsset(Release rel, out string setup, out string sums) {
        setup = null; sums = null;
        string fallback = null;
        if (rel.Assets != null)
            foreach (var a in rel.Assets) {
                if (a.Name == null) continue;
                if (a.Name.EndsWith("setup.exe")) setup = a.Url;
                else if (a.Name.StartsWith("SHA256")) sums = a.Url;
                else if (a.Name.EndsWith(".zip")) fallback = a.Url;
            }
        if (setup == null) setup = fallback;
    }

    static string ExpectedHash(string sumsText, string fileName) {
        foreach (var line in sumsText.Split('\n')) {
            var m = Regex.Match(line.Trim(), @"^([0-9a-fA-F]{64})\s+\*?(.+)$");
            if (m.Success && m.Groups[2].Value.Trim() == fileName)
                return m.Groups[1].Value;
        }
        return null;
    }

    static string Sha256(string path) {
        using (var sha = System.Security.Cryptography.SHA256.Create())
        using (var f = File.OpenRead(path))
            return BitConverter.ToString(sha.ComputeHash(f)).Replace("-", "");
    }

    static int CreateTask() {
        string exe = Path.Combine(InstallDir, ExeName);
        var p = Process.Start(new ProcessStartInfo {
            FileName = "schtasks.exe",
            Arguments = "/Create /TN \"" + TaskName + "\" /TR \"\\\"" + exe + "\\\" /Auto\" /SC DAILY /ST 12:00 /F",
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        });
        string so = p.StandardOutput.ReadToEnd();
        string se = p.StandardError.ReadToEnd();
        p.WaitForExit();
        if (p.ExitCode != 0)
            File.WriteAllText(Path.Combine(Path.GetTempPath(), "sentinel-updater-diag.txt"),
                "schtasks exit=" + p.ExitCode + "\n" + so + se);
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
}
