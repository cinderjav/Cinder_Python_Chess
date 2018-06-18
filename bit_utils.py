from enums import WHITE_TURN, BLACK_TURN

def getbitIndex(x):
    count = 0
    while x > 0:
        val = x & 1
        if val > 0:
            return count
        else:
            x = x >> 1
            count += 1
    return -1

def countBits(x):
    result = 0
    while x > 0:
        x = x & (x-1)
        result += 1
    return result

def swap_turns(turn):
    return WHITE_TURN if turn == BLACK_TURN else BLACK_TURN