FROM ruby:3.4

RUN apt-get update && apt-get install -y systemd systemd-sysv openssh-server sudo redis-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd --system --gid 1000 deploy && \
    useradd deploy --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R deploy:deploy /var
RUN echo "deploy ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/deploy
RUN echo 'deploy:password' | chpasswd

# Enable systemd lingering for deploy user
RUN mkdir -p /var/lib/systemd/linger && touch /var/lib/systemd/linger/deploy

EXPOSE 22
CMD ["/lib/systemd/systemd"]