--[[
    Train and test several LSTM architectures.
]]


require 'optim'
local Logger = optim.Logger
paths.dofile('../projectdir.lua')

local logger_filename = paths.concat(projectDir,'exp', 'ucf_sports', 'test_lstm_arch.log')
if not paths.dirp(paths.dirname(logger_filename)) then
    print('Creating dir: ' .. paths.dirname(logger_filename))
    os.execute('mkdir -p ' .. paths.dirname(logger_filename))
end
logger = optim.Logger(logger_filename, false)
logger:setNames{'ExperimentID','Top-1 accuracy (%)','Top-5 accuracy (%)', 'Average Precision'}

------------------------------------------------------------------------------------------------------------

local function exec_command(command)
    print('\n')
    print('Executing command: ' .. command)
    print('\n')
    os.execute(command)
end

------------------------------------------------------------------------------------------------------------

local function read_log_file(opt)
    local filename = paths.concat(projectDir, 'exp', opt.dataset, opt.expID, 'Evaluation_full.log')
    if paths.filep(filename) then
        local file = io.open(filename, 'r')
        local stats
        for line in file:lines() do
            stats = string.split(line, '\t')
        end
        file:close()
        return stats
    end
    return nil
end

------------------------------------------------------------------------------------------------------------

local function log(opt)
    local stats = read_log_file(opt)  -- get accuracy from the network
    logger:add{opt.expID, tonumber(stats[1]), tonumber(stats[2]), tonumber(stats[3])}
end

------------------------------------------------------------------------------------------------------------

local function get_configs()
    return {
        -- experiment id
        dataset = 'ucf_sports',

        -- model
        nFeats = 512,
        nLayers = 2,

        -- data
        inputRes = 256,
        scale = 0,
        rotate = 30,
        rotRate = .5,

        -- train options
        optMethod = 'adam',
        LR = 1e-4,
        nThreads = 4,
        nEpochs = 10,
        trainIters = 300,
        testIters = 100,
        seq_length = 32,
        batchSize = 4,
        grad_clip = 10,
        snapshot = 0,
        nGPU = 1,
        continue = 'false',
        saveBest = 'true',
        clear_buffers = 'true',

        -- test options
        test_progressbar = 'false',
        test_load_best = 'true'
    }
end

------------------------------------------------------------------------------------------------------------

local test_opts = {
    -- lstm
    --{expID = 'lstm-test1', netType = 'vgg16-lstm'},
    {expID = 'lstm-test2', netType = 'vgg16-lstm2', convert_cudnn = 'true'},
    {expID = 'lstm-test3', netType = 'hms-lstm', convert_cudnn = 'true'},

}

for i, test_opt in ipairs(test_opts) do
    print('\n=======================================================')
    print(('Starting train+test configuration: %d/%d'):format(i, #test_opts))
    print('=======================================================\n')

    -- set train + test options
    local opts = get_configs()
    for k, v in pairs(test_opt) do
        opts[k] = v
    end

    -- concatenate options fields to a string
    local str_args = ''
    for k, v in pairs(opts) do
        str_args = str_args .. ('-%s %s '):format(k, v)
    end

    -- train network
    exec_command(('th train.lua %s'):format(str_args))

    -- test network
    exec_command(('th test.lua %s'):format(str_args))

    -- log best accuracy
    log(opts)
end

