# https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/
FROM centos:8 as centos-systemd
ENV container docker
ENV CEPHADM_PATH=/usr/local/sbin/cephadm

# Centos met EOL and the content of the CentOS 8 repos has been moved to vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

RUN dnf -y install chrony firewalld lvm2 \
  openssh-server openssh-clients python3 \
  yum-utils sudo which && dnf clean all

RUN systemctl enable chronyd firewalld sshd


FROM centos-systemd as centos-systemd-docker
# To cache cephadm images
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf -y install docker-ce && \
    dnf clean all && systemctl enable docker

# ssh utilities
RUN dnf install epel-release -y && dnf makecache && dnf install sshpass -y

EXPOSE 8443
EXPOSE 22

FROM centos-systemd-docker
WORKDIR /root

CMD [ "/usr/sbin/init" ]
