function test_hello_output
    set output (hello)
    if test $output = 'Hello, world from FishBox!'
        echo 'Test passed: hello function works.'
    else
        echo 'Test failed: unexpected output:' $output
    end
end
