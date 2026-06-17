namespace eRentaCar.API.Helpers
{
    public static class EnvHelper
    {
        public static void Load(string path = ".env")
        {
            if (!File.Exists(path)) return;
            foreach (var line in File.ReadAllLines(path))
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("#")) continue;
                var index = trimmed.IndexOf('=');
                if (index < 0) continue;
                var key = trimmed[..index].Trim();
                var value = trimmed[(index + 1)..].Trim();
                Environment.SetEnvironmentVariable(key, value);
            }
        }

        public static string Get(string key)
        {
            return Environment.GetEnvironmentVariable(key)
                ?? throw new Exception($"Environment varijabla '{key}' nije postavljena.");
        }
    }
}