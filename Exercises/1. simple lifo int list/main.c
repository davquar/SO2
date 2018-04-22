/**
 * This program is a simple implementation of a LIFO list.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

typedef struct node {
    int value;
    struct node* next;
} node;

node* addToList(int value, node** list);
void printList(node* list);
void acceptValues(node** list);

int main() {
    node* list;
    list = (node*) malloc(sizeof(node));
    list = NULL;

    acceptValues(&list);

    printList(list);
}

node* addToList(int value, node** list) {
    node* newNode = (node*) malloc(sizeof(node));
    newNode->value = value;
    newNode->next = NULL;

    if (*list == NULL) {
        *list = newNode;
    } else {
        newNode->next = *list;
        *list = newNode;
    }

    return newNode;
}

void printList(node* list) {
    node* i = list;
    while (i != NULL) {
        printf("%d ", i->value);
        i = i->next;
    }
}

void acceptValues(node** list) {
    int input;
    while (true) {
        printf("Enter the new integer > 0: ");
        scanf("%d", &input);
        if (input == 0) break;
        addToList(input, list);
    }
}