#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/if.h>
#include <signal.h>
#include <unistd.h>

#define MAX_BUF_LEN 1024
#define MULTICAST_GROUP "239.0.0.1"
#define PORT 8080

struct ifreq ifr;
int sockfd;
struct sockaddr_in addr;
char buffer[MAX_BUF_LEN];
const char *interface = "ens1";

void sig_handler(int signum)
{
    switch (signum) {
        case SIGINT:
            printf("\nReceived SIGINT signal.\n");
            break;
        case SIGHUP:
            printf("\nReceived SIGHUP signal.\n");
            break;
        case SIGTERM:
            printf("\nReceived SIGTERM signal.\n");
            break;
        default:
            printf("\nReceived unknown signal.\n");
            break;
    }
    printf("Socket closing\n");
    int i = close(sockfd);
    if (i != 0) {
        printf("Error: Could not close socket");
    }
    exit(0);
}

int main(int argc, char* argv[])
{
    if (argc > 1) {
        interface = argv[1];
    }

    signal(SIGINT, sig_handler);
    signal(SIGHUP, sig_handler);
    signal(SIGTERM, sig_handler);

    // Create a socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");
        exit(1);
    }

    // Set to use interface enp1s3 only
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), interface);
    if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, (void *)&ifr, sizeof(ifr)) < 0) {
        perror("Cannot find network interface");
        exit(1);
    }

    // Set up the sockaddr_in structure
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    // Bind the socket to the multicast address
    if (bind(sockfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }

    // Join the multicast group
    struct ip_mreq mreq;
    memset(&mreq, 0, sizeof(mreq));
    mreq.imr_multiaddr.s_addr = inet_addr(MULTICAST_GROUP);
    mreq.imr_interface.s_addr = htonl(INADDR_ANY);
    if (setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq)) < 0) {
        perror("setsockopt");
        exit(1);
    }

    // Receive multicast packets
    while (1) {
        ssize_t num_bytes = recv(sockfd, buffer, MAX_BUF_LEN, 0);
        if (num_bytes < 0) {
            perror("recv");
            exit(1);
        }
        buffer[num_bytes] = '\0';
        printf("Received: %s", buffer);
    }

    return 0;
}
