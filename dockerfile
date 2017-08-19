FROM microsoft/aspnetcore-build:2.0.0-jessie AS builder
WORKDIR /source
COPY *.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish --output /app/ --configuration Release

FROM microsoft/aspnetcore:2.0.0-jessie
WORKDIR /app
COPY --from=builder /app .
ENTRYPOINT ["dotnet", "ClientCertificateCheck.dll", "ServerCert.pfx", "password"]
CMD ["8443"]