using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Diagnostics.Tracing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NuGet.Services.Monitoring
{
    public class MonitoringHub
    {
        public IReadOnlyList<EventSource> EventSources { get; private set; }

        public MonitoringHub()
        {
            EventSources = new List<EventSource>().AsReadOnly();
        }

        public virtual void ScanForSources()
        {
            // Iterate over every assembly and locate the event source types
            EventSources = EventSource.GetSources().ToList();
        }

        public virtual async Task DumpSourceList(string tempDir)
        {
            using (var writer = OpenEventSourceFile(tempDir))
            {
                await writer.WriteLineAsync("id,name,type");
                foreach (var source in EventSources)
                {
                    await writer.WriteAsync(source.Guid.ToString());
                    await writer.WriteAsync(",");
                    await writer.WriteAsync(source.Name);
                    await writer.WriteAsync(",\"");
                    await writer.WriteAsync(source.GetType().AssemblyQualifiedName);
                    await writer.WriteLineAsync("\"");
                }
            }
        }

        protected internal virtual StreamWriter OpenEventSourceFile(string tempDir)
        {
            string fileName = Path.Combine(
                tempDir, String.Format(CultureInfo.InvariantCulture, "EventSources.{0}.csv", Process.GetCurrentProcess().Id));
            if (!Directory.Exists(tempDir))
            {
                Directory.CreateDirectory(tempDir);
            }
            return new StreamWriter(fileName, append: false);
        }
    }
}
