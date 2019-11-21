FROM mcr.microsoft.com/dotnet/core/sdk:2.1
RUN apt-get install git
COPY TestNirvana.sh /
RUN bash /TestNirvana.sh
