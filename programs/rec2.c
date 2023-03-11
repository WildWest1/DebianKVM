#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <signal.h>
#include <net/if.h>
#include <linux/in.h>

#define MAX_BUF_LEN 1024
#define MULTICAST_GROUP "239.0.0.1"
#define PORT 8080

int sockfd;
struct sockaddr_in local_addr, multicast_addr;
char buffer[MAX_BUF_LEN];
socklen_t addrlen = sizeof(multicast_addr);
ssize_t recvlen;
struct ifreq ifr;
const char *interface = "enp1s3";
struct ip_mreq mc_req;

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

int main(int argc, char* argv[]) {

    if (argc > 1) {
        interface = argv[1];
    }

    signal(SIGINT, sig_handler);
    signal(SIGHUP, sig_handler);
    signal(SIGTERM, sig_handler);

    // create socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    // Set to use interface enp1s3 only
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), interface);
    if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, (void *)&ifr, sizeof(ifr)) < 0) {
        perror("Cannot find network interface");
        exit(1);
    }

    
    // bind to local address
    memset(&local_addr, 0, sizeof(local_addr));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(PORT);
    if (bind(sockfd, (struct sockaddr *)&local_addr, sizeof(local_addr)) < 0) {
        perror("bind");
        exit(EXIT_FAILURE);
    }
    

    // join multicast group
    mc_req.imr_multiaddr.s_addr = inet_addr(MULTICAST_GROUP);
    mc_req.imr_interface.s_addr = htonl(INADDR_ANY);

    //memset(&multicast_addr, 0, sizeof(multicast_addr));
    //multicast_addr.sin_family = AF_INET;
    //multicast_addr.sin_addr.s_addr = inet_addr(MULTICAST_GROUP);
    //multicast_addr.sin_port = htons(PORT);
    
    //if (setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &multicast_addr, sizeof(multicast_addr)) < 0) {
    
    if (setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mc_req, sizeof(mc_req)) < 0) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }

    // receive multicast messages
    while (1) {
        memset(buffer, 0, MAX_BUF_LEN);
        recvlen = recvfrom(sockfd, buffer, MAX_BUF_LEN, 0, (struct sockaddr *)&multicast_addr, &addrlen);
        if (recvlen < 0) {
            perror("recvfrom");
            exit(EXIT_FAILURE);
        }
        printf("Received %zd bytes from %s:%d: %s\n", recvlen, inet_ntoa(multicast_addr.sin_addr), ntohs(multicast_addr.sin_port), buffer);
    }

    close(sockfd);
    return 0;
}
