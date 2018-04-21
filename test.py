import pandas as pd
import numpy as np


def main():
    df = pd.DataFrame({'A': 'foo bar foo bar foo bar foo foo'.split(),
                       'B': 'one one two three two two one three'.split(),
                       'C': np.arange(8), 'D': np.arange(8) * 2})
    print(df)
    #      A      B  C   D
    # 0  foo    one  0   0
    # 1  bar    one  1   2
    # 2  foo    two  2   4
    # 3  bar  three  3   6
    # 4  foo    two  4   8
    # 5  bar    two  5  10
    # 6  foo    one  6  12
    # 7  foo  three  7  14

    print(df.loc[df['A'] == 'foo'])
    output = df.loc[df['D'].be < 10]
    print(output)

if __name__ == "__main__":
    main()


