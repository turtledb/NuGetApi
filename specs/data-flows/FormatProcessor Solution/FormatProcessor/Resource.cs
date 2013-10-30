﻿using System;
using System.Diagnostics;
using System.IO;
using Newtonsoft.Json.Linq;

namespace FormatProcessor {
    public class Resource {
        readonly JObject _jsonDoc;

        protected Resource(JObject jsonDoc) {
            _jsonDoc = jsonDoc;
        }

        public static Resource LoadString(string data) {
            if(data == null)
                throw new ArgumentNullException("data");
            try {
                var json = JObject.Parse(data);
                var r = new Resource(json);
                return r;
            }
            catch (Exception ex) {
                Trace.TraceError(ex.ToString());
                throw new FormatException(ex.Message);
            }
        }

        public static Resource LoadUrl(Uri uri) {
            // todo: examine the uri scheme and switch resolver to a UNC file resolver
            // todo: refactor HttpLinkResolver creation to a dependency resolver that can be mocked
            return LoadUrl(uri, new HttpLinkResolver());
        }

        public static Resource LoadUrl(Uri url, ILinkResolver resolver) {
            var resourceString = resolver.Get(url);
            return LoadString(resourceString);
        }

        public object Root {
            get {
                return _jsonDoc.Root;
            }
        }
    }
}