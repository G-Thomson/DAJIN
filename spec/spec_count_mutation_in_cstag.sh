#!/bin/sh
# shellcheck disable=SC2120

Describe 'minimap2のcsタグを用いて変異塩基の数をカウントする'
    Describe 'count_mutation_in_cstag'
    # Define function <<<<<<<<<<<<<<<<<
        count_mutation_in_cstag()(
            if [ -p /dev/stdin ] && [ "$*" = "" ]; then
                cat -
            elif [ -f "$*" ]; then
                cat "$*"
            else
                echo "$*"
            fi |
            awk '{sum=0
            sub("cs:Z:", "")
            gsub(/[-=+~]/, "")
            gsub(/\*[acgt][acgt]/, " 1 ")
            gsub(/[acgt]/, " 1 ")
            gsub(/[ACGT]/, " 0 ")
            for(i=1;i<=NF;i++) sum+=$i
            print sum }'
        )

        Example 'すべてマッチしているので"0"'
            When call count_mutation_in_cstag "=AAAA"
            The output should equal '0'
        End

        Example '=AAA+aAA" -> 1塩基挿入なので"1"を返す'
            When call count_mutation_in_cstag "=AAA+aAA"
            The output should equal '1'
        End

        Example '"=AAA-aAA" -> 1塩基欠失なので"1"を返す'
            When call count_mutation_in_cstag "=AAA-aAA"
            The output should equal '1'
        End

        Example '=AAA*acAA" -> 1塩基置換なので"1"を返す'
            When call count_mutation_in_cstag "=AAA*acAA"
            The output should equal '1'
        End

        Example '"=AAA+aa-g*acAA" -> 2塩基挿入, 1塩基欠失, 1塩基置換なので"2+1+1=4"'
            When call count_mutation_in_cstag "=AAA+aa-g*acAA"
            The output should equal '4'
        End

        Example '=AAA~cg6~aaAA" -> 10塩基の大型欠失なので"10"を返す'
            When call count_mutation_in_cstag "=AAA~cg6~aaAA"
            The output should equal '10'
        End

        Example 'Use pipe output as a shell script argument'
            test_fn()(echo "$1" | count_mutation_in_cstag)
            When call test_fn "=AAA+aa-g*acAA"
            The output should equal '4'
        End
    End
End
