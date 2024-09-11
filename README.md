# 🔄 RISC-V Multi-Cycle Processor

## 📘 Overview

This project implements a **multi-cycle processor** based on the **RISC-V architecture** and designed for the **cyclone v board**. The processor is modeled as a **Moore machine**, where each instruction is executed across multiple clock cycles, taking a `[6:0]op` as input and producing sets of outputs. The project includes all essential components, such as flip-flops, memory, and an ALU, written in **SystemVerilog**, with distinct sections for the **datapath** and **controller**.
![top](https://github.com/user-attachments/assets/a551447f-5ea8-42eb-83cc-cbb8bd1ee65b)




## ✨ Key Features

- 🖥️ **Multi-Cycle Execution**: Instructions are executed across multiple clock cycles, optimizing resource usage.
- 🧠 **Moore Machine**: Takes a `[6:0]op` input and produces outputs based on the current state of the processor.
- 📂 **Datapath and Controller Sections**: Separate sections for the datapath (data flow) and the controller (control signals).
- 🧠 **Modular Design**: Includes all necessary modules, such as **flip-flops**, **memory**, **ALU**, and more, all written in **SystemVerilog**.
- 📦 **RISC-V Instruction Set Support**: Implements a subset of the RISC-V instruction set, including arithmetic, logic, memory, and control instructions.
- 📝 **Simulation and Testing**: The project includes test cases and simulation files to verify processor functionality using RISC-V programs.
- ![risc-v](https://github.com/user-attachments/assets/684663d7-a0ff-4dde-a635-f04eeacc37da)

## 🛠️ Processor Stages

1. **Instruction Fetch (IF)**: Fetches the instruction based on the program counter (PC).
2. **Instruction Decode (ID)**: Decodes the instruction and reads registers.
3. **Execution (EX)**: Performs arithmetic/logic operations or computes memory addresses.
4. **Memory Access (MEM)**: Accesses memory as needed (e.g., load/store instructions).
5. **Write-Back (WB)**: Writes the result back to the register file.

![moore](https://github.com/user-attachments/assets/d4c5feee-5958-421d-9028-9aaf41453f4e)


## 🧩 Modules

- **Flip-Flops**: Sequential storage elements for state holding.
- **Memory**: Includes both instruction and data memory.
- **ALU**: Executes arithmetic and logic operations.
- **Register File**: Contains 32 general-purpose registers.
- **Control Unit**: Manages control signals based on the current state of the processor.


## 🛠️ Processor Features

- **ALU Operations**: Supports basic arithmetic and logic operations.
- **Branching and Jumping**: Implements branch (e.g., BEQ, BNE) and jump instructions (e.g., JAL, JALR).
- **Memory Access**: Implements load and store operations.
- **Register File**: Contains 32 registers, following the RISC-V specification.

## 📂 Datapath and Controller

- **Datapath**: Handles the flow of data between the ALU, memory, and registers.
   ![datapath](https://github.com/user-attachments/assets/028da244-844c-4d7f-9775-1521d4a7e448)

- **Controller**: Produces control signals based on the current instruction and stage of execution.
  ![Controller](https://github.com/user-attachments/assets/12f21c4d-b018-4c17-baa6-94d7c1867dcb)


## 🖥️ Synthesis for cyclone v Board

- **Board Design**: The processor design is synthesized for the **cyclone v board**, ensuring compatibility and optimal performance.
- **Synthesis Stage**: This stage focuses on translating the processor design into a hardware circuit suitable for the cyclone v board, mapping the processor components to specific hardware resources. The design is optimized for both performance and area constraints.
![rtl](https://github.com/user-attachments/assets/fa013236-a26b-4035-a00d-9ea0fbdc130d)

## 📈 Performance

- **Clock Cycles**: Each instruction is divided into five stages, executed over multiple clock cycles.
- **Throughput**: Multi-cycle execution optimizes resource usage by splitting instructions into stages, improving performance.
