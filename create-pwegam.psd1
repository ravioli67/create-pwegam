@{
    RootModule        = 'create-pwegam.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a7b3c9d1-4e2f-48a1-9c5d-8f1e2b3a4c5d'
    Author            = 'Ravi Dave'
    Description       = 'CLI scaffolder for Pwegam, a hybrid 2D/3D ASCII game engine for PowerShell.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('create')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('GameEngine', 'ASCII', '3D', '2D', 'CLI', 'Pwegam')
            ProjectUri = 'https://github.com/ravioli67/create-pwegam'
        }
    }
}
