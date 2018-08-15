namespace eval Buoyancy::xml {
    # Namespace variables declaration
    variable dir
}

proc Buoyancy::xml::Init { } {
    # Namespace variables initialization
    variable dir
    Model::InitVariables dir $Buoyancy::dir

    Model::ForgetConstitutiveLaws
    Model::getConstitutiveLaws ConstitutiveLaws.xml

    Model::ForgetMaterials
    Model::getMaterials Materials.xml

    Model::getSolvers "../../Common/xml/Solvers.xml"
    
    [Model::getCondition "Outlet2D"] setAttribute ElementType "Point,Line"
    set topObj [::Model::Topology new "Point" 1 "Condition2D1N"]
    [Model::getCondition "Outlet2D"] addTopologyFeature $topObj

    [Model::getCondition "Outlet3D"] setAttribute ElementType "Point,Line,Surface"
    set topObj [::Model::Topology new "Point" 1 "Condition3D1N"]
    [Model::getCondition "Outlet3D"] addTopologyFeature $topObj
    set topObj [::Model::Topology new "Line" 2 "Condition3D2N"]
    [Model::getCondition "Outlet3D"] addTopologyFeature $topObj

    # Hide Fluid gravity -> Boussinesq
    #spdAux::SetValueOnTreeItem state hidden FLGravity
}

proc Buoyancy::xml::getUniqueName {name} {
    return ${::Buoyancy::prefix}${name}
}

proc Buoyancy::xml::CustomTree { args } {
    Buoyancy::write::UpdateUniqueNames Fluid
    apps::setActiveAppSoft Fluid
    Fluid::xml::CustomTree

    Buoyancy::write::UpdateUniqueNames ConvectionDiffusion
    apps::setActiveAppSoft ConvectionDiffusion
    ConvectionDiffusion::xml::CustomTree

    Buoyancy::write::UpdateUniqueNames Buoyancy
    apps::setActiveAppSoft Buoyancy

    # Modify the tree: field newValue UniqueName OptionalChild
    spdAux::SetValueOnTreeItem v "Monolithic" FLSolStrat
    spdAux::SetValueOnTreeItem v "Yes" FLStratParams compute_reactions
}

# Overwriting some procs
# proc spdAux::injectNodalConditionsOutputs {basenode args} {
#     set base [$basenode parent]
#     set args {*}$args
#     if {$args eq ""} {
#         set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
#         set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
#     }
#     return [spdAux::injectNodalConditionsOutputs_do $basenode $args]
# }

# proc spdAux::injectElementOutputs {basenode args} {
#     set base [$basenode parent]
#     set args {*}$args
#     if {$args eq ""} {
#         set app [apps::getAppById [spdAux::GetAppIdFromNode $base]]
#         set args [list ImplementedInApplication [join [$app getKratosApplicationName] ","]]
#     }
#     return [spdAux::injectElementOutputs_do $basenode $args]
# }

Buoyancy::xml::Init
