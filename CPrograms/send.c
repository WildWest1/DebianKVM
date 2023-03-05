#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>
#include <net/if.h>

#define MULTICAST_IP "239.0.0.1"
#define PORT 8080

int sockfd;
struct sockaddr_in multicast_addr;
struct ifreq ifr;

void sendMessage(char message[]){
    if (sendto(sockfd, message, strlen(message), 0, (struct sockaddr *)&multicast_addr, sizeof(multicast_addr)) < 0) {
        perror("sendto failed");
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char* argv[]) {

    // Create a UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Set to use interface enp1s3 only
    const char *interface;
    interface = "ens1p3";
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), interface);
    if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, (void *)&ifr, sizeof(ifr)) < 0) {
        perror("Cannot find network interface");
        exit(1);
    }

    // Set the TTL (time to live) of the multicast packets to 1
    int ttl = 1;
    if (setsockopt(sockfd, IPPROTO_IP, IP_MULTICAST_TTL, (void *)&ttl, sizeof(ttl)) < 0) {
        perror("setsockopt failed");
        exit(EXIT_FAILURE);
    }

    // Set up the multicast address structure
    memset(&multicast_addr, 0, sizeof(multicast_addr));
    multicast_addr.sin_family = AF_INET;
    multicast_addr.sin_addr.s_addr = inet_addr(MULTICAST_IP);
    multicast_addr.sin_port = htons(PORT);

    while(1) {
        char message[100];
        if (argc > 1) {
            int length = strlen(argv[1]);
            strcpy(message, argv[1]);
            message[length] = '\n'; // Receiver won't flush buffer without the newline char
        }
        else {
            printf("Enter message: ");
            fgets(message, sizeof(message), stdin);
        }
        sendMessage(message);
        sleep(1);
    }
    close(sockfd);

    return 0;
}
