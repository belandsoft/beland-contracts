module.exports = {
              compilers: {
                solc: {
                  version: '0.8.3',
                  settings: {
                    optimizer: {
                      enabled: true,
                      runs: 2000,
                    },
                    evmVersion: istanbul
                  }
                }
              }
            }