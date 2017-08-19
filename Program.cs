using System;
using System.Net;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Server.Kestrel.Https;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;

namespace ClientCertificateCheck
{
    public class Program
    {
        public static void Main(string[] args)
        {
            if (args.Count() != 2)
            {
                return;
            }
            BuildWebHost(args).Run();
        }

        public static IWebHost BuildWebHost(string[] args) =>
            WebHost.CreateDefaultBuilder()
                .UseStartup<Startup>()
                .UseKestrel(options =>
                {
                   options.Listen(IPAddress.Loopback, 8443, listenOptions =>
                   {
                       var certificate = new X509Certificate2(args[0], args[1]);
                       HttpsConnectionAdapterOptions httpsOption = new HttpsConnectionAdapterOptions();
                       httpsOption.SslProtocols = SslProtocols.Tls;
                       httpsOption.ClientCertificateMode = ClientCertificateMode.AllowCertificate;
                       httpsOption.ClientCertificateValidation = (inCertificate, inChain, inPolicy) => {return true;};
                       httpsOption.CheckCertificateRevocation = false;
                       httpsOption.ServerCertificate = certificate;
                       //listenOptions.UseHttps("ServerCert.pfx","password");
                       listenOptions.UseHttps(httpsOption);
                       
                   });
                })
                .Build();
    }
}
