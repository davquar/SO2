#include <stdlib.h>
#include <stdbool.h>

/**
 * Simple Binary Search Tree (BST) implementation.
*/

typedef struct node {
    int value;
    struct node* parent;
    struct node* left;
    struct node* right;
} node;

/**
 * Executes a DFS visit and prints the node's value.
 * @param root the node to start the visit from.
 */
void dfsVisit(node *root) {
    printf("%d ", root->value);
    if (root->left != NULL) dfsVisit(root->left);
    if (root->right != NULL) dfsVisit(root->right);
}

/**
 * Searches the tree for a node with the given value.
 * @param value the value to search for
 * @param root the node to start the search from
 * @param returnParent true to return the last visited node, if the given value doesn't exist in the tree
 * @return the node with the given value, or the node that should be its parent (if inserted).
 */
node* search(int value, node* root, bool returnParent) {
    if (value == root->value) return root;
    if (value < root->value && root->left != NULL) return search(value, root->left, returnParent);
    if (value > root->value && root->right != NULL) return search(value, root->right, returnParent);
    return returnParent ? root : NULL;
}

/**
 * Shorthand function to check if the given value exists in the tree.
 * @param value the value to search for
 * @param root the node to start searching from
 * @return true if exists
 */
bool contains(int value, node* root) {
    return search(value, root, false) == NULL ? false : true;
}

/**
 * Inserts the given value in the given tree, without duplicates.
 * @param value the value to insert.
 * @param root the root of a (sub)tree.
 * @return true if inserted.
 */
bool insert(int value, node** root) {
    node* newNode = (node*) malloc(sizeof(node));
    newNode->value = value;
    newNode->parent = NULL;
    newNode->left = NULL;
    newNode->right = NULL;

    if (*root == NULL) {
        *root = newNode;
    } else {
        node* parent = search(value, *root, true);
        newNode->parent = parent;
        if (parent == NULL)
            *root = newNode;
        else if (value < parent->value)
            parent->left = newNode;
        else if (value > parent->value)
            parent->right = newNode;
        else if (value == parent->value) {
            free(newNode);
            return false;
        }
    }
    return true;
}

/**
 * Deletes the node with the given value, from the given tree.
 * @param value the value to search for.
 * @param tree the tree to search into.
 * @return true if deleted.
 */
bool delete(int value, node** tree) {
    node* found = search(value, *tree, false);
    if (found == NULL)  return false;

    bool isLeftChild = found->value < found->parent->value;
    if (isLeftChild) found->parent->left = NULL;
    else found->parent->right = NULL;
    free(found);
    return true;
}