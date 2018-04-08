# Exercise 3 of Homework 1

Write a `gawk` script called `3.awk` that works on `k` CSV files.

Each file represents a shift division for an exam.

```text
|*    9:00     *|*     10:00     *|*  11:00     *|
|     57620 |  32091 |    105793    |
|   122828 |   132521 |     135768    |
...     ...         ...         ...         ...
```

Breaking it down:

- the **separator** is the character `|`;
- the **header** is in the format `HH:MM`;
- each **field** contains a *freshman ID (matricola)*:
  - numeric;
  - can contain 1+ spaces before and after.

The meaning is that students under the column `i` do the exam at the shift represented in the `i` column header.

## Script definition

We can have several versions of a shift division. Given two versions `i` and `i+1`, the script should find all the changed IDs.

Specifically, its output should be based on this set of rules:

- Shift change: "La matricola `m` e' stata **spostata** dal turno `i` al turno `j` nel passare dalla versione `i` alla versione `i+1`";
- ID deleted: "La matricola `m` e' stata **cancellata** nel passare dalla versione `i` alla versione `i+1`";
- ID added: "La matricola `m` e' stata **aggiunta** nel passare dalla versione `i` alla versione `i+1`";

## Output ordering

For each set of versions `i` and `i+1` the script should output things basing of these rules:

- Ordering by ID (asc);
- Type of change order:
  1. Shift change;
  2. ID deleted;
  3. ID added.

## Notes

- Don't write anything on *stderr*;
- Don't write anything on *stdout* except for the defined things;
- Max execution time for tests: 10 minutes.