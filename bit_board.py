from enums import WHITE_TURN, BLACK_TURN
from move_generation import generate_moves
from bit_utils import swap_turns

class BitBoard:
    def __init__(self, gameBoard, whitePieces, blackPieces, whitePiecesDict, blackPiecesDict, turn):
        self.gameBoard = gameBoard
        self.whitePieces = whitePieces
        self.blackPieces = blackPieces
        self.whitePiecesDict = whitePiecesDict
        self.blackPiecesDict = blackPiecesDict
        self.turn = turn

    def get_pieces_dict_for_turn(self):
        return self.whitePiecesDict if self.turn == WHITE_TURN else self.blackPiecesDict
    
    def get_pieces_bitboard_for_turn(self):
        return self.whitePieces if self.turn == WHITE_TURN else self.blackPieces
    
    def get_pieces_bitboard_for_enemy_turn(self):
        enemyTurn = swap_turns(self.turn)
        return self.whitePieces if enemyTurn == WHITE_TURN else self.blackPieces
    
    def get_pieces_dict_for_enemy_turn(self):
        return self.whitePiecesDict if self.turn == BLACK_TURN else self.blackPiecesDict
    
    def generate_moves_for_turn(self):
        currentPiecesDict = self.get_pieces_dict_for_turn()
        currentPiecesBitBoard = self.get_pieces_bitboard_for_turn()
        enemiesPiecesBitBoard = self.get_pieces_bitboard_for_enemy_turn()
        return generate_moves(currentPiecesDict, currentPiecesBitBoard, enemiesPiecesBitBoard, self.turn)
        
