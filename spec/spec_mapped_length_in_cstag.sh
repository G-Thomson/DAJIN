#!/bin/sh
# shellcheck disable=SC2120

Describe 'minimap2のcsタグを用いてマッピングした塩基数をカウントする'
    Describe ' '
    # Define function <<<<<<<<<<<<<<<<<
        mapped_length_in_cstag()(
            if [ -p /dev/stdin ] && [ "$*" = "" ]; then
                cat -
            elif [ -f "$*" ]; then
                cat "$*"
            else
                echo "$*"
            fi |
            awk '{sum=0
            sub("cs:Z:", "")
            gsub(/[-=+]/, "")
            gsub(/~[acgt][acgt][0-9]*[acgt][acgt]/, " 0 ")
            gsub(/\*[acgt][acgt]/, " 0 ")
            gsub(/[acgt]/, " 0 ")
            gsub(/[ACGT]/, " 1 ")
            for(i=1;i<=NF;i++) sum+=$i
            print sum }'
        )

        Example 'すべてマッチしているので"5"を返す'
            When call mapped_length_in_cstag "=AAAAA"
            The output should equal '5'
        End

        Example '=AAA+aAA" -> 1塩基挿入を無視して"5"を返す'
            When call mapped_length_in_cstag "=AAA+aAA"
            The output should equal '5'
        End

        Example '"=AAA-aAA" -> 1塩基欠失を無視して"5"を返す'
            When call mapped_length_in_cstag "=AAA-aAA"
            The output should equal '5'
        End

        Example '=AAA*acAA" -> 1塩基置換を無視して"5"を返す'
            When call mapped_length_in_cstag "=AAA*acAA"
            The output should equal '5'
        End

        Example '"=AAA+aa-g*acAA" -> 2塩基挿入, 1塩基欠失, 1塩基置換をを無視して"5"を返す'
            When call mapped_length_in_cstag "=AAA+aa-g*acAA"
            The output should equal '5'
        End

        Example '=AAA~cg6~aaAA" -> 10塩基の大型欠失を無視して"5"を返す'
            When call mapped_length_in_cstag "=AAA~cg6aa=AA"
            The output should equal '5'
        End

        Example 'Use pipe output as a shell script argument'
            test_fn()(echo "$1" | mapped_length_in_cstag)
            When call test_fn "=AAA+aa-g*acAA"
            The output should equal '5'
        End
    End
End
