proc ::PfemThermic::examples::ThermicSloshing {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
        if { $retval == "cancel" } { return }
    }

    Kratos::ResetModel
    DrawThermicSloshingGeometry$::Model::SpatialDimension
    AssignGroupsThermicSloshingGeometry$::Model::SpatialDimension
    TreeAssignationThermicSloshing$::Model::SpatialDimension

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

# Draw Geometry
proc PfemThermic::examples::DrawThermicSloshingGeometry2D {args} {
    ## Layer ##
	set layer PfemThermic
    GiD_Layers create $layer
    GiD_Layers edit to_use $layer

    ## Points ##
    set points_inner [list 0 0 0 3.0 0 0 3.0 0.3 0 0 0.5 0]
    foreach {x y z} $points_inner {
        GiD_Geometry create point append $layer $x $y $z
    }
    set points_outer [list 0 1.0 0 3.0 1.0 0]
    foreach {x y z} $points_outer {
        GiD_Geometry create point append $layer $x $y $z
    }
	
	## Lines ##
    set lines_inner [list 1 2 2 3 3 4 4 1]
    foreach {p1 p2} $lines_inner {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    set lines_outer [list 4 5 5 6 6 3]
    foreach {p1 p2} $lines_outer {
        GiD_Geometry create line append stline $layer $p1 $p2
    }
    
    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface 2 3 4 1 escape escape
}

proc PfemThermic::examples::DrawThermicSloshingGeometry3D {args} {
    # To be implemented
}

# Group assign
proc PfemThermic::examples::AssignGroupsThermicSloshingGeometry2D {args} {
    GiD_Groups create Fluid
    GiD_Groups edit color Fluid "#26d1a8ff"
    GiD_EntitiesGroups assign Fluid surfaces 1

    GiD_Groups create Rigid_Walls
    GiD_Groups edit color Rigid_Walls "#e0210fff"
    GiD_EntitiesGroups assign Rigid_Walls lines {1 2 4 5 6 7}

}
proc PfemThermic::examples::AssignGroupsThermicSloshingGeometry3D {args} {
    # To be implemented
}

# Tree assign
proc PfemThermic::examples::TreeAssignationThermicSloshing2D {args} {
    # Physics
	spdAux::SetValueOnTreeItem v "Fluids" PFEMFLUID_DomainType
	
	# Create bodies
	set bodies_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]"
    gid_groups_conds::copyNode $bodies_xpath [spdAux::getRoute PFEMFLUID_Bodies]
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@n='Body'\]\[2\]" {name Body2}
	
	# Fluid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/value\[@n='BodyType'\]" {v Fluid}
    set fluid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body1'\]/condition\[@n='Parts'\]"
    set fluidNode [customlib::AddConditionGroupOnXPath $fluid_part_xpath Fluid]
    set props [list ConstitutiveLaw NewtonianTemperatureDependent2DLaw DENSITY 1000 CONDUCTIVITY 100.0 SPECIFIC_HEAT 10.0 DYNAMIC_VISCOSITY 0.001 BULK_MODULUS 2100000000.0]
    spdAux::SetValuesOnBaseNode $fluidNode $props
	
	# Rigid body
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='BodyType'\]" {v Rigid}
    set rigid_part_xpath "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/condition\[@n='Parts'\]"
    set rigidNode [customlib::AddConditionGroupOnXPath $rigid_part_xpath Rigid_Walls]
    $rigidNode setAttribute ov line
    gid_groups_conds::setAttributesF "[spdAux::getRoute PFEMFLUID_Bodies]/blockdata\[@name='Body2'\]/value\[@n='MeshingStrategy'\]" {v "No remesh"}
   
    # Velocity BC
    GiD_Groups clone Rigid_Walls Total
    GiD_Groups edit parent Total Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//Total"
    GiD_Groups edit state "Rigid_Walls//Total" hidden
    set fixVelocity "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='VELOCITY'\]"
    set fixVelocityNode [customlib::AddConditionGroupOnXPath $fixVelocity "Rigid_Walls//Total"]
    $fixVelocityNode setAttribute ov line
	
	# Temperature BC
	GiD_Groups clone Rigid_Walls TotalT
    GiD_Groups edit parent TotalT Rigid_Walls
    spdAux::AddIntervalGroup Rigid_Walls "Rigid_Walls//TotalT"
    GiD_Groups edit state "Rigid_Walls//TotalT" hidden
    set fixTemperature "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
    set fixTemperatureNode [customlib::AddConditionGroupOnXPath $fixTemperature "Rigid_Walls//TotalT"]
    $fixTemperatureNode setAttribute ov line
	set props [list value 263.15 Interval Total]
    spdAux::SetValuesOnBaseNode $fixTemperatureNode $props
	
	# Temperature IC
	GiD_Groups clone Fluid Initial
    GiD_Groups edit parent Initial Fluid
	spdAux::AddIntervalGroup Fluid "Fluid//Initial"
	GiD_Groups edit state "Fluid//Initial" hidden
	set thermalIC "[spdAux::getRoute PFEMFLUID_NodalConditions]/condition\[@n='TEMPERATURE'\]"
	set thermalICnode [customlib::AddConditionGroupOnXPath $thermalIC "Fluid//Initial"]
	$thermalICnode setAttribute ov surface
	set props [list value 283.15 Interval Initial]
    spdAux::SetValuesOnBaseNode $thermalICnode $props
	
	# Time parameters
    set time_parameters [list StartTime 0.0 EndTime 0.04 DeltaTime 0.001 UseAutomaticDeltaTime No]
    set time_params_path [spdAux::getRoute "PFEMFLUID_TimeParameters"]
    spdAux::SetValuesOnBasePath $time_params_path $time_parameters
	
	# Parallelism
    set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 1]
    set xpath [spdAux::getRoute "Parallelization"]
    spdAux::SetValuesOnBasePath $xpath $parameters
	
    spdAux::RequestRefresh
}

proc PfemThermic::examples::TreeAssignationThermicSloshing3D {args} {
    # To be implemented
}

proc PfemThermic::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}