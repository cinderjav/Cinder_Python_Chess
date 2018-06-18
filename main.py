from board_generation import convert_board_to_bitboard
from enums import WHITE_TURN
from move_transition import reorder_moves, get_can_move_pieces, decoupled_pieces_ordered, execute_move

board = [
    ["r","n","b","q","k","b","n","r"],
    ["p","p","p","p","p","p","p","p"],
    ["","","","","","","",""],
    ["","","","","","","",""],
    ["","","","","","","",""],
    ["","","","","","","",""],
    ["P","P","P","P","P","P","P","P"],
    ["R","N","B","Q","K","B","N","R"]
]

#get fen and convert to board, and set turn
bit_board = convert_board_to_bitboard(board, WHITE_TURN)
#method entry point
#evaluate board with level termination

overallMoves, currentMovesDict = bit_board.generate_moves_for_turn()
decoupled_moves_ordered = reorder_moves(overallMoves, bit_board.get_pieces_bitboard_for_enemy_turn())
#for loop of moves starts here on outer
can_move_pieces = get_can_move_pieces(currentMovesDict, decoupled_moves_ordered[0], bit_board.turn)
decoupled_pieces = decoupled_pieces_ordered(can_move_pieces, bit_board.get_pieces_dict_for_turn(), decoupled_moves_ordered[0], bit_board.turn, bit_board.get_pieces_bitboard_for_enemy_turn(), bit_board.get_pieces_bitboard_for_turn())
#inner for loop here
new_bit_board = execute_move(decoupled_pieces[0], decoupled_moves_ordered[0], bit_board)
print(new_bit_board.gameBoard)
#call method with new bitboard





