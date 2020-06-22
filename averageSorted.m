function output = averageSorted(input)
    input = cell2mat(input);
    if length(input) > 19
        input = (input(1:2:end,:) +  input(2:2:end,:)) / 2;
    end
    output = input(5:14,:);
    output(2:5,2) = (output(2:5,2) + flipud(input(1:4,2)))/2;
    output(6:9,2) = (output(6:9,2) + flipud(input(15:18,2)))/2;
    return