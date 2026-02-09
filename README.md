# Hamming Code Decoder and Error Correction (x86 Assembly)

This project implements a **Hamming Code decoder** written in **x86 Assembly**, capable of detecting and correcting transmission errors in a **21-bit Hamming-encoded binary sequence**.  
The program supports **single-bit error correction**, **double-bit error detection**, and decodes the original data into **ASCII characters**.

---

## Project Overview

The application:
- reads a 21-bit Hamming-encoded binary sequence
- allows the user to select **even or odd parity**
- validates input (only `0` and `1`)
- computes the **global parity bit**
- calculates the **syndrome**
- detects and corrects **single-bit errors**
- detects **double-bit errors**
- extracts and decodes the original data bits into ASCII characters

---

## Features

- Support for **even and odd parity**
- **Single-bit error detection and correction**
- **Double-bit error detection**
- Syndrome calculation using parity bits (positions 1, 2, 4, 8, 16)
- Global parity verification
- ASCII character reconstruction
- Detection of non-printable characters
- Input validation and informative error messages

---

## Input Format

1. Parity type:
   - `0` → Even parity
   - `1` → Odd parity
2. A **21-bit binary sequence** consisting only of `0` and `1`

--Example:
--0
--101100110101011001101


## Output

Depending on the input, the program:
- confirms correct transmission
- corrects and reports a single-bit error (with its position)
- detects and reports two-bit errors
- displays the decoded ASCII characters (if printable)

---

## Program Structure

### Data Segment
- User messages
- Input buffer for the 21-bit sequence
- Syndrome storage
- Global parity bit
- Decoded characters
- Error position variable

### Procedures
- `verificareBiti` — computes global parity and syndrome, detects and corrects errors
- `verificarePutereALui2` — checks if a position is a power of two (parity bit)
- `caractereNeprintabile` — verifies printable ASCII characters

---

## Error Detection Logic

- Syndrome = 0 → no error
- Syndrome ≠ 0 and global parity matches → **single-bit error** (corrected)
- Syndrome ≠ 0 and global parity differs → **double-bit error detected**

---

## Technologies Used

- x86 Assembly (16-bit, TASM/MASM syntax)
- DOS interrupts (`INT 21h`)
- Bitwise operations and parity checks
