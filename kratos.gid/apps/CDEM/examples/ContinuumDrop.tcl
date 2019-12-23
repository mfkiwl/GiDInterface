
proc ::CDEM::examples::ContinuumDrop {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    DrawGeometry
    AssignToTree
    AssignMeshSize

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame

    MeshGenerationOKDo 1.0

}

proc ::CDEM::examples::DrawGeometry { } {
    Kratos::ResetModel

    GiD_Groups create "Box"
    GiD_Groups create "Sand"
    GiD_Groups create "TopPart"
    GiD_Groups create "MidPart"
    GiD_Groups create "LowPart"
    GiD_Groups create "Low-MidCohesive"

    GiD_Process Mescape Geometry Create Line -10 20 0 -10 0 0 escape escape
    GiD_Process Mescape Geometry Create Line -9 0 0 9 0 0 escape escape
    GiD_Process Mescape Geometry Create Line 10 0 0 10 20 0 escape escape
    GiD_EntitiesGroups assign "Box" lines 1
    GiD_EntitiesGroups assign "Box" lines 2
    GiD_EntitiesGroups assign "Box" lines 3

    GiD_Process Mescape Geometry Create Object Rectangle -8 1 0 8 4 0 escape
    GiD_EntitiesGroups assign "Sand" surfaces 1

    GiD_Process Mescape Geometry Create Object Rectangle -5 5 0 5 10 0 escape
    GiD_Process Mescape Geometry Create Object Rectangle -6 10 0 6 15 0 escape
    GiD_Process Mescape Geometry Create Object Rectangle -4 16 0 4 20 0 escape
    GiD_EntitiesGroups assign "LowPart" surfaces 2
    GiD_EntitiesGroups assign "MidPart" surfaces 3
    GiD_EntitiesGroups assign "TopPart" surfaces 4

    GiD_EntitiesGroups assign "Low-MidCohesive" surfaces 2
    GiD_EntitiesGroups assign "Low-MidCohesive" surfaces 3



}


proc ::CDEM::examples::AssignToTree { } {
    # Material
    set DEMmaterials [spdAux::getRoute "DEMMaterials"]
    set props [list PARTICLE_DENSITY 2500.0 YOUNG_MODULUS 1.0e7 PARTICLE_MATERIAL 2 ]
    set material_node [[customlib::GetBaseRoot] selectNodes "$DEMmaterials/blockdata\[@name = 'DEMCont-DefaultMaterial' \]"]
    foreach {prop val} $props {
        set propnode [$material_node selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Material $prop"
        }
    }

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts LowPart]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEMCont-DefaultMaterial"]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts MidPart]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEMCont-DefaultMaterial"]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts TopPart]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEMCont-DefaultMaterial"]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }

    # Parts
    set DEMParts [spdAux::getRoute "DEMParts"]
    set DEMPartsNode [customlib::AddConditionGroupOnXPath $DEMParts Sand]
    $DEMPartsNode setAttribute ov surface
    set props [list Material "DEMCont-DefaultMaterial"]
    foreach {prop val} $props {
        set propnode [$DEMPartsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Parts $prop"
        }
    }

    # DEM FEM Walls
    set DEMConditions [spdAux::getRoute "DEMConditions"]
    set box "$DEMConditions/condition\[@n='DEM-FEM-Wall2D'\]"
    set wallsNode [customlib::AddConditionGroupOnXPath $box Box]
    $wallsNode setAttribute ov line
    set props [list ]
    foreach {prop val} $props {
        set propnode [$wallsNode selectNodes "./value\[@n = '$prop'\]"]
        if {$propnode ne "" } {
            $propnode setAttribute v $val
        } else {
            W "Warning - Couldn't find property Wall2D $prop"
        }
    }

    # # Inlet
    # set DEMInlet "$DEMConditions/condition\[@n='Inlet'\]"
    # set inletNode [customlib::AddConditionGroupOnXPath $DEMInlet "Inlet"]
    # $inletNode setAttribute ov surface
    # set props [list Material "DEM-DefaultMaterial" ParticleDiameter 0.13 InVelocityModulus 2.3 InDirectionVector "0.0,0.0,-1.0"]
    # foreach {prop val} $props {
    #     set propnode [$inletNode selectNodes "./value\[@n = '$prop'\]"]
    #     if {$propnode ne "" } {
    #         $propnode setAttribute v $val
    #     } else {
    #         W "Warning - Couldn't find property Inlet $prop"
    #     }
    # }


    # cohesiveTop
    set cohesiveTop "$DEMConditions/condition\[@n='DEM-Cohesive2D'\]"
    set cohesivenode [customlib::AddConditionGroupOnXPath $cohesiveTop "TopPart"]
    $cohesivenode setAttribute ov surface

    # cohesiveMid-Low
    set cohesiveTop "$DEMConditions/condition\[@n='DEM-Cohesive2D'\]"
    set cohesivenode [customlib::AddConditionGroupOnXPath $cohesiveTop "Low-MidCohesive"]
    $cohesivenode setAttribute ov surface




    # General data
    # Time parameters
    set change_list [list EndTime 20 DeltaTime 1e-5 NeighbourSearchFrequency 20]
    set xpath [spdAux::getRoute DEMTimeParameters]
    foreach {name value} $change_list {
        set node [[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check ContinuumDrop script"
        }
    }

    # Bounding box
    set change_list [list UseBB false MinZ -1.0]
    set xpath [spdAux::getRoute Boundingbox]
    foreach {name value} $change_list {
        set node [[customlib::GetBaseRoot] selectNodes "$xpath/value\[@n = '$name'\]"]
        if {$node ne ""} {
            $node setAttribute v $value
        } else {
            W "Couldn't find $name - Check ContinuumDrop script"
        }
    }

    spdAux::RequestRefresh
}

proc ::CDEM::examples::AssignMeshSize { } {
    GiD_Process Mescape Meshing AssignSizes Volumes 0.2 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Surfaces 1 1:end escape escape escape
    GiD_Process Mescape Meshing AssignSizes Lines 1 1:end escape escape escape
}


proc ::CDEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}