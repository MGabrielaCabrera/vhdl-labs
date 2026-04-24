## SystemVerilog Randomization Exercises


> After reviewing Chapter 6 of "SYSTEMVERILOG FOR VERIFICATION" book
> of Chris Spear, some exercises has been asked to Claude to review 
> the learned concepts:

---

## Exercise 1 — rand vs randc

**File:** `ex01_rand_vs_randc.sv`

Create a class with two 3-bit variables: one that can repeat values
across randomization calls, and one that cannot repeat a value until
all possible values in its range have been generated.

Randomize the class 16 times and print both values on each iteration.
Observe the difference in behavior between the two variables.

**Goals:**
- Understand the two types of random variables in SystemVerilog
- Observe uniform independent draws vs cyclic exhaustion

---

## Exercise 2 — Equality and Set Membership Constraints

**File:** `ex02_equality_inside.sv`

Create a class representing a bus transaction with an 8-bit address,
an 8-bit data field, and a 2-bit burst length.

Add constraints so that:
- The address is restricted to a specific contiguous range
- The data can only take a small set of specific byte values
- The burst length is always the same fixed value

Randomize 10 times and verify all constraints hold.

**Goals:**
- Fix a variable to a specific value using a constraint
- Restrict a variable to a range or an explicit list of values

---

## Exercise 3 — Weighted Distributions with dist

**File:** `ex03_dist.sv`

Create a class with a 2-bit packet type and an 8-bit payload.

Add constraints so that:
- The packet type follows a weighted distribution where each
  individual value has its own assigned weight
- The payload favors the lower half of its range over the upper half,
  but the weight is split evenly across all values within each half

Randomize 1000 times, count occurrences of each packet type, and
verify the distribution roughly matches your weights.

**Goals:**
- Assign weight per individual value vs weight shared across a range
- Observe probabilistic distribution over many iterations

---

## Exercise 4 — Implication Constraints

**File:** `ex04_implication.sv`

Create a class representing a memory access with a write enable bit,
an 8-bit address, and an 8-bit data field.

Add constraints so that:
- When it is a write operation, the address must always be even
- When it is a read operation, the data field must be zero

Randomize 10 times and verify both rules are respected.

**Goals:**
- Express "if condition, then rule" using the implication operator
- Understand that the rule is only enforced when the condition is true

---

## Exercise 5 — Conditional Constraints (if-else)

**File:** `ex05_if_else.sv`

Create a class with a write enable bit, an 8-bit data field,
and a 2-bit mode selector.

Add a single constraint block so that:
- Write operations produce non-zero data and restrict the mode to
  a specific subset of values
- Read operations force data to zero and fix the mode to a
  specific value

Randomize 10 times and confirm every case follows the rules.

**Goals:**
- Use if-else inside a constraint block for multi-branch logic
- Understand that constraints are solved simultaneously, not
  sequentially like procedural code

---

## Exercise 6 — Bidirectional Constraints

**File:** `ex06_bidirectional.sv`

Create a class with a 1-bit flag and a 4-bit value. Add a single
constraint that ties the flag directly to whether the value exceeds
a threshold.

Randomize 10 times and verify that the flag is always consistent
with the value. Then, without changing the class, force the flag
to be set from the testbench and observe how the value is
automatically restricted as a consequence.

**Goals:**
- Observe that the solver satisfies all constraints simultaneously
- Understand that fixing one variable can implicitly constrain others

---

## Exercise 7 — solve...before

**File:** `ex07_solve_before.sv`

Create a class with a 1-bit flag and a 3-bit value. Add a constraint
so that when the flag is set, the value must be zero.

Without any ordering hint, randomize 1000 times and count how often
the flag is set. Then add a directive that tells the solver to
determine the flag first, before solving for the value. Randomize
1000 times again and compare the flag distribution.

**Goals:**
- Guide solver ordering to change the probability of outcomes
- Understand that this does not change which solutions are legal,
  only how often each is chosen

---

## Exercise 8 — constraint_mode and rand_mode

**File:** `ex08_dynamic_control.sv`

Reuse the class from Exercise 2. In your testbench:

1. Disable the address range constraint at runtime. Randomize 5 times
   and verify the address is no longer restricted.
2. Re-enable it.
3. Prevent the data field from changing on each randomization call.
   Randomize 5 more times and verify it stays fixed.
4. Re-enable normal randomization for data.

**Goals:**
- Toggle specific constraint blocks on and off during simulation
- Freeze a random variable to its current value for specific tests

---

## Exercise 9 — Inline Constraints

**File:** `ex09_inline_constraints.sv`

Create a class with an 8-bit address and an 8-bit data field.
Define no constraints inside the class itself.

In the testbench, run three rounds of 5 randomizations each:
1. No extra constraints
2. Force the address above a high threshold
3. Force data to be odd and address below a low threshold

Do not modify the class for any round.

**Goals:**
- Add one-off constraints directly at the call site
- Understand why this is useful for directed tests without
  touching the original class

---

## Exercise 10 — pre_randomize and post_randomize

**File:** `ex10_pre_post_randomize.sv`

Create a class with a 4-element fixed array of 8-bit values and
two non-random fields: one used as an upper bound for the array
values, and one that stores a derived result.

Before each randomization, set the upper bound to a chosen value
and make sure the constraint respects it. After each randomization,
compute the derived field as the XOR of all array elements.

Randomize 5 times, print the array and the derived value, and
manually verify one result by hand.

**Goals:**
- Configure non-random state before the solver runs
- Derive secondary fields from freshly randomized values

---

## Exercise 11 — Array Constraints

**File:** `ex11_array_constraints.sv`

Create a class with a dynamic array of unsigned integers and a
separate variable that controls how many elements it will have.

Add constraints so that:
- The number of elements is in a specific range
- The array size matches that variable
- Every element falls within a given range
- The total sum of all elements stays below a fixed limit
- Elements are in strictly ascending order

Randomize 5 times and print the array and its sum each time.

> When constraining `sum()`, cast each element to a wider type
> to avoid overflow. Example: `data.sum() with (int'(item)) < 500`

**Goals:**
- Constrain size, individual elements, and aggregate properties
- Apply ordering constraints across array elements with foreach
- Handle sum overflow correctly

---

## Exercise 12 — randcase

**File:** `ex12_randcase.sv`

In a testbench module, without using a class, simulate a bus arbiter
that selects one of three masters. Assign different weights to each
master so that one is selected most often and one the least.

Run 1000 selections, count the results, and verify they roughly
match your intended weights.

**Goals:**
- Make weighted random choices procedurally without a class
- Understand randcase as a lightweight alternative for simple
  weighted selection

---

## Exercise 13 — randsequence

**File:** `ex13_randsequence.sv`

Model a simplified transaction stream where each sequence begins
with either a write or a read. A write is usually followed by a
success response but occasionally by an error. A read is always
followed by a data response.

Generate 10 sequences and print each step in order.

**Goals:**
- Generate ordered, grammar-based stimulus with randsequence
- Understand when it is the right tool over randcase or constraints

---

## Exercise 14 — Seeds and Random Stability

**File:** `ex14_seeds_stability.sv`

Create a class with several random fields. Then:

1. Run the simulation twice with different seed values and confirm
   you get different stimulus each time.
2. In a single simulation, create two instances of the class and
   verify they produce independent sequences from each other.
3. Add a second randomizable class. Verify that adding or removing
   randomization calls in one class does not affect the sequence
   produced by the other.

**Goals:**
- Control the random stream through simulator seeds
- Observe that each object has its own independent random state
- Appreciate per-object stability across unrelated changes

---

## Simulation results:

Due to the randomization limitations in the free version of ModelSim,
the EDA Playground web has been used to simulated the exercises. The
simulator used was Aldec Riviera.

The simulation results are in the issue:

https://github.com/MGabrielaCabrera/vhdl-labs/issues/20
