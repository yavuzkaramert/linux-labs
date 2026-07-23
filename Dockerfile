FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo vim curl net-tools tree && \
    rm -rf /var/lib/apt/lists/*

# ubuntu:24.04 ships a default "ubuntu" user at uid 1000 — remove it so
# "student" can take uid 1000
RUN userdel -r ubuntu && \
    useradd -m -s /bin/bash -u 1000 student && \
    echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student && \
    chmod 440 /etc/sudoers.d/student

CMD ["sleep", "infinity"]
