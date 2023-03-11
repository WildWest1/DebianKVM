#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <net/if.h>
#include <signal.h>

#define MAX_BUF_LEN 1024
#define MULTICAST_GROUP "239.0.0.1"
#define PORT 8080

struct ifreq ifr;
int sockfd;
struct sockaddr_in group_addr;
char buffer[MAX_BUF_LEN];
const char *interface = "enp1s3";

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

int main() {

    signal(SIGINT, sig_handler);
    signal(SIGHUP, sig_handler);
    signal(SIGTERM, sig_handler);
    int ret;

    // create a UDP socket
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

    // set the reuse address option
    int reuse_addr = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &reuse_addr, sizeof(reuse_addr)) < 0) {
        perror("setsockopt");
        exit(1);
    }

    // join the multicast group
    memset(&group_addr, 0, sizeof(group_addr));
    group_addr.sin_family = AF_INET;
    group_addr.sin_addr.s_addr = inet_addr(MULTICAST_GROUP);
    group_addr.sin_port = htons(PORT);
    ret = setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &group_addr, sizeof(group_addr));
    if (ret < 0) {
        perror("setsockopt");
        exit(1);
    }

    // bind the socket to the port
    struct sockaddr_in bind_addr = {0};
    bind_addr.sin_family = AF_INET;
    bind_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    bind_addr.sin_port = htons(PORT);
    if (bind(sockfd, (struct sockaddr *)&bind_addr, sizeof(bind_addr)) < 0) {
        perror("bind");
        exit(1);
    }

    printf("Joined multicast group %s on port %d\n", MULTICAST_GROUP, PORT);

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
