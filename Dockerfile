FROM cm2network/steamcmd:latest

USER root

RUN apt-get update -y

RUN apt-get install wine -y

RUN apt-get install gettext-base -y

RUN apt-get install xvfb -y

RUN apt-get install x11-utils -y

RUN apt-get install procps -y

RUN apt-get install tini -y

RUN dpkg --add-architecture i386 && apt-get update && apt-get install wine32 -y

RUN apt-get install winbind -y

RUN apt-get install nodejs npm -y

RUN npm install -g bun

RUN mkdir /saves

RUN chown steam /saves

ENV DISPLAY=:99

RUN winecfg

USER steam

RUN ./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +app_update 1829350 validate +quit

COPY ./templates /templates

COPY entrypoint.sh /

COPY launch_server.sh /

COPY launch_script.sh /

COPY launch-server.ts /
COPY bun.lock /
COPY package.json /
COPY tsconfig.json /
COPY .env.deployed /.env
COPY ./prisma/schema.prisma /prisma/schema.prisma
COPY ./prisma/migrations /prisma/migrations

USER root

RUN bun install --frozen-lockfile

RUN bun generate

RUN chown -R steam /saves

RUN chmod +x /launch_server.sh

RUN chmod +x /entrypoint.sh

RUN chmod +x /launch_script.sh

# RUN chmod +x /launch-server.ts
# RUN chmod +x /bun.lock
# RUN chmod +x /package.json
# RUN chmod +x /tsconfig.json

# RUN ln -s /saves/Settings/launch-server.ts /launch-server.ts
# RUN ln -s /saves/Settings/bun.lock /bun.lock
# RUN ln -s /saves/Settings/package.json /package.json
# RUN ln -s /saves/Settings/tsconfig.json /tsconfig.json

EXPOSE 27020/udp
EXPOSE 27020/tcp
EXPOSE 27021/udp
EXPOSE 27021/tcp
EXPOSE 27022/udp
EXPOSE 27022/tcp
EXPOSE 27023/udp
EXPOSE 27023/tcp

USER steam

ENTRYPOINT [ "/entrypoint.sh" ]
