# Exercise 1 of Homework 1

Write a bash script `1.sh` with the synopsis `1.sh [opt] matr dir_so1_old dir_so1_new dir_so2`.
The scripts calculates the score of a student (identified by his ID (*matricola*)) for the course **Sistemi Operativi**.

Sistemi Operativi is divided in two modules, that we call **SO1** and **SO2**. To verbalize Sistemi Operativi, students need to pass the two distinct modules.

## Invocation

The **options** can be:

- `-y <year>` (default: 2018): selects the year;
- `-n <number of years>` (default: 1): determines the expiration of a partial score;
- `-1`: selects the latest result of SO1;
- `-2`: selects the latest result of SO2.

### Errors

The script should also spit out something if bad things happen, such as:

#### Incorrect invocation

- Non-existent option;
- No argument given;
- `-1` and `-2` used together;
- Mandatory arguments missing.

In that case, it should **print the use on stderr**, and **exit with status code 10**.

#### Permission sadness

Every directory given as argument should be usable, so we can define two cases to handle:

- A directory doesn't exist;
- A directory isn't readable and executable for the current user.

In that case, it should print an error and **exit with status code 100**.

## Rules

Basically students need to score at least 18/31 for each module, and the final score is their average, rounded at the nearest integer. It uses the *Unbiased Bankers' Rounding*.

Scores "expire" after `n` solar years are passed between a module and another.

Things are not so clean, because each module has its own ~~shit~~ modalities. And they changed over time. So we need to define and handle two exam modalities.

### SO1

For the first module, we need to distinguish between exams done before and after a certain year (2017), where modalities changed.

#### SO1 before 2017

The old exam for the first module is defined as follows:

- 3 written levels (l1, l2, l3);
- students need to pass them all;
- score = l1 + l2 + l3;
- if (score > 31) --> score = 31

These results are stored in CSV files, one for each exam session and level.

The file **structure** looks like:

```text
old_res[0-9]+$/
    res_yyyy_m_d_L1.csv
    res_yyyy_m_d_L2.csv
    res_yyyy_m_d_L3.csv
    ...
```

- `yyyy`: year;
- `m`: month;
- `d`: day;
- `Ll`: level.

Each CSV file contains the following **fields**:

- name;
- surname;
- matricola (student ID);
- score (integer part);
- score (decimal part);

A quick note is that an exam is considered completed if the L3 is done. If a student retires himself before the L3, she maintais her previous L3 score.

#### SO1 after 2017

The new exam for the first module is defined as follows:

- written test;
- optional oral (overwrites the written);

The results are stored in CSV files, this time with more structure:

```text
new_res[0-9]+$/
	aaaabbbb/
        esami/
            appelli/
                date.txt
                sa/
                sb/
                ...
                sx/
                    bocciati.txt
                    promossi.web
                    orali.txt
```

This needs a bit of explaination. Let's look at the content of these files:

##### date.txt

It maps an exam session name (label; *sx* in the previous example) to a date.

```text
1:2017/1/10
2:2017/2/16
extra1:2017/3/20
...:...
```

Data about the exam session defined on each line is stored inside a folder named as the label.

##### bocciati.txt

Each line contains a *matricola* of a student who failed in that exam session. This file has more priority over the next two.

##### promossi.web

Each line is a wiki table entry, so it looks like: `|matricola|score|`. It means that the student with that *matricola* passed the exam with the specified score.

##### orali.txt

Formatted like the previous. These students also are in `promossi.web`, but this score has more priority (it is the final). They are the students who passed the oral exam.

### SO2

Same rules of SO1 > 2017.

## Output

Given a *matricola* `m`, the script's output should be ruled by these cases:

- `m` passed SO1 and SO2 --> print "Risultato finale per la matricola `m`: `so1_score` (`so1_date`) + `so1_score` (`so2_date`) = `score`":
  - date format: dd/mm/yyyy;
  - score precision:
    - old mode --> 1 decimal digit;
    - new mode --> integer.
- `m` only passed SO1 --> print "Risultato parziale modulo `i` per la matricola `m`: `so1_score` (`so1_date`)";
- `m` passed SO1 and SO2 after more than `n` years --> same;
- `-1` given --> latest SO1 result;
- `-2` given --> latest SO2 result;
- no results for `m` --> don't print anything.