#include <stdio.h>
#include "bst.h"

void main() {
    node* tree = NULL;

    insert(5, &tree);
    insert(0, &tree);
    insert(10, &tree);
    insert(10, &tree);
    insert(15, &tree);
    insert(17, &tree);
    insert(20, &tree);
    insert(7, &tree);
    insert(8, &tree);
    insert(-1, &tree);
    insert(3, &tree);
    insert(2, &tree);
    insert(4, &tree);
    insert(1, &tree);

    dfsVisit(tree);
    printf("\n%s\n", contains(7, tree) ? "Contains 7" : "Doesn't contain 7");

    delete(7, &tree);
    dfsVisit(tree);
    printf("\n%s\n", contains(7, tree) ? "7 is still here" : "7 isn't here anymore");
}