use alexandria_data_structures::stack::{StackTrait, Felt252Stack, NullableStack};

fn char_count(str: felt252) -> u32 {
    let u_str: u256 = str.try_into().unwrap();
    let mut r = u_str;
    let mut char_count: u32 = 1;
    while (r > 255) {
        r = r / 255;
        char_count += 1;
    };
    return char_count;
}

fn apply_instr(
    instr: u8,
    ref cell_pointer: felt252,
    ref cells: Felt252Dict<u8>,
    cmd_sequence: @ByteArray,
    ref loop_starts: Felt252Stack<u32>,
    ref cmd_index: u32
) {
    if instr == 62 { // >
        cell_pointer += 1;
        let cell_ptr_u32: u32 = cell_pointer.try_into().unwrap();
        if cell_ptr_u32 >= 255 {
            //overflow
            cell_pointer = 0;
        }

    } else if instr == 60 { // <
        let cell_ptr_u32: u32 = cell_pointer.try_into().unwrap();
        if cell_ptr_u32 == 0 {
            //underflow
            cell_pointer = 255;
        } else {
            cell_pointer -= 1;
        }

    } else if instr == 43 { //+
        let cell_value = cells.get(cell_pointer);
        if cell_value < 255 {
            cells.insert(cell_pointer, cell_value + 1);
        } else {
            //overflow
            cells.insert(cell_pointer, 0);
        }

    } else if instr == 45 { //-
        let cell_value = cells.get(cell_pointer);
        if cell_value > 0 {
            cells.insert(cell_pointer, cell_value - 1);
        } else {
            cells.insert(cell_pointer, 255);
        }

    } else if instr == 91 { // [
        let cell_value = cells.get(cell_pointer);
        if cell_value == 0 {
            let mut nest_level = 1; //enter loop current loop
            while nest_level != 0 { //look for imbricated loop in the current loop
                cmd_index += 1; //skip next command while inside current loop
                let mut cmd = cmd_sequence.at(cmd_index);
                match cmd {
                    Option::Some(instr) => {
                        if instr == 91 { // [
                            nest_level += 1; //new nested loop
                        }
                        if instr == 93 { // ]
                            nest_level -= 1; //end of nested loop
                        }
                    },
                    Option::None => println!("End"),
                };
            };
        } else {
            //record start of loop that will be executed
            loop_starts.push(cmd_index);
        }

    } else if instr == 93 { // ]
        let cell_value = cells.get(cell_pointer);
        let mut jump_back_loop = loop_starts.pop(); //cmd_index gets value from index of loop start
        if cell_value != 0 {
            match jump_back_loop {
                Option::Some(jump_back_loop) => cmd_index = jump_back_loop - 1, //-1 or it skips cmd
                Option::None => println!("Nothing to unwrap "),
            };
        }

    } else if instr == 46 { //.
        let cell_value = cells.get(cell_pointer);
        let mut printed_cell: ByteArray = "";
        printed_cell.append_byte(cell_value);
        println!("{printed_cell}"); // print character at current cell

    } else if instr == 44 { //,
        println!("Input char");
    }
}

fn main() {
    let program: Array<felt252> = array![
        76272362702276292945988669437848119356379865657543813111902929447471037500, //++++++++[>++++[>++>+++>+++>+<<<
        106323916294499839195369545401478271543999052954073198074265923948632550187, //<-]>+>+>->>+[<]<-]>>.>---.+++++
        76272443898053169474361755807993312465657195906153000643606855882394905901, //++..+++.>>.<-.<.+++.------.----
        833358791099224566574 //----.>>+.
    ];

    let mut cell_pointer: felt252 = 0;
    let mut cells: Felt252Dict<u8> = Default::default();

    let mut loop_starts = StackTrait::<Felt252Stack, u32>::new(); //loop stack

    let mut program_index = 0;
    let mut cmd_sequence: ByteArray = "";
    let program_length = program.len();

    //convert felt252 array into single ByteArray to iterate individual char using .at() (not possible with felt)
    while program_index < program_length {
        let mut cmd_sequence_felt = *program.at(program_index);
        let mut len_cmd_seq_felt = char_count(cmd_sequence_felt);

        cmd_sequence.append_word(cmd_sequence_felt, len_cmd_seq_felt);
        program_index += 1;
    };
    println!("Program : {cmd_sequence}");

    let cmd_sequence_length = cmd_sequence.len();
    let mut cmd_index: u32 = 0;

    while cmd_index < cmd_sequence_length {
        //match individual character to instructions +, -, >, <, etc.
        let mut cmd = cmd_sequence.at(cmd_index);
        match cmd {
            Option::Some(instr) => {
                apply_instr(
                    instr,
                    ref cell_pointer,
                    ref cells,
                    @cmd_sequence,
                    ref loop_starts,
                    ref cmd_index
                )
            },
            Option::None => println!("End Of Sequence"),
        };
        cmd_index += 1;
    };
}


