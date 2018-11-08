# utility for advanced meshing features in DEM
proc DEM::write::Elements_Substitution {} {
    global KPriv
    variable ndime
    set fail 0
    package require math::statistics
    set seed [expr srand(0)]
    set gelemlist [::wkcf::GetDEMActiveElements]
    set final_list_of_isolated_nodes [list]
    foreach celemid $gelemlist {
	set cgroupidlist [::xmlutils::setXmlContainerIds {DEM//c.DEM-Elements//c.DEM-Element}]
	set cohesive_groups_list [::xmlutils::setXmlContainerIds {DEM//c.DEM-Cohesivegroup}]

	if {![GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE]} {
	    GiD_Groups create SKIN_SPHERE_DO_NOT_DELETE
	}

	foreach cgroupid $cgroupidlist { ; #Loop on each of the groups, be it a point, a line, a triangle, etc
	    set list_of_elements_to_add_to_skin_sphere_group [list]
	    array set my_prop [join [::xmlutils::setXmlContainerPairs "DEM//c.DEM-Elements//c.DEM-Element//c.$cgroupid//c.Properties" {} dv]]
	    set use_advanced_meshing_features $my_prop(AdvancedMeshingFeatures)
	    if {([lsearch $cohesive_groups_list $cgroupid] == -1) && ($KPriv(what_dempack_package) eq "C-DEMPack") && ($use_advanced_meshing_features eq "No")} { ; #Non-cohesive, already meshed with cuban mesher
		set cgroupid_elements [GiD_EntitiesGroups get $cgroupid elements]

		foreach cgroupid_element $cgroupid_elements {
		    if {[lsearch [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements] $cgroupid_element] == -1} {
		        lappend list_of_elements_to_add_to_skin_sphere_group $cgroupid_element
		    }
		}
		GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
		continue
	    }

	    if {$use_advanced_meshing_features eq "Yes"} {
		if {$my_prop(AdvancedMeshingFeaturesAlgorithmType) eq "FEMtoDEM"} {
		    set use_fem_to_dem $my_prop(FEMtoDEM)
		    set element_radius [expr {0.5*$my_prop(Diameter)}]
		    set standard_deviation $my_prop(StandardDeviation)
		    set probldistr $my_prop(ProbabilityDistribution)
		    set min_radius [expr {0.5*$element_radius}] ; # HARDCODED THE CRITERIA TO CHOOSE BOTH MINIMUM AND MAXIMUM RADIUS
		    set max_radius [expr {1.5*$element_radius}]
		    if {$use_fem_to_dem == "AttheCentroid"} {
		        set nodes_to_delete [list]
		        set element_ids [GiD_EntitiesGroups get $cgroupid elements] ; # We get the ids of all the elements in cgroupid
		        array set is_external_element [DEM::write::Compute_External_Elements $ndime $cgroupid $element_ids]

		        foreach element_id $element_ids { ; # Here we loop on each of the elements by id
		            if {$ndime == "3D"} {
		                set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end] ; # We get the nodes of the element
		            } else {
		                set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end]
		            }
		            lappend nodes_to_delete {*}$element_nodes ; # We add those nodes to the nodes_to_delete list
		            if {$probldistr == "NormalDistribution"} {
		                set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            } else {
		                set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            }
		            set node_id [GiD_Mesh create node append [DEM::write::GetElementCenter $element_id]] ; # We create a new node starting from the center of the given element

		            if {$ndime == "3D"} {
		                set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		                if {($is_external_element($element_id)==1) && ([lsearch $cohesive_groups_list $cgroupid] != -1)} {
		                    GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $new_element_id
		                }
		            } else {
		                set new_element_id [GiD_Mesh create element append circle 1 $node_id $final_elem_radius 0 0 1] ; # We assume the 2D problem is contained in the XY plane
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		                if {($is_external_element($element_id)==1) && ([lsearch $cohesive_groups_list $cgroupid] != -1)} {
		                    GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $new_element_id
		                }
		            }
		            foreach container_group [GiD_EntitiesGroups entity_groups elements $element_id] { ; # We get the list of groups to which the element with id $element_id belongs
		                GiD_EntitiesGroups assign $container_group elements $new_element_id ; # We assign the element with id $new_element_id to each of the groups in the loop
		            }
		        }

		        if {[lsearch $cohesive_groups_list $cgroupid] == -1} {
		            GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
		        }

		        GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type hexahedra]
		        GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type tetrahedra]
		        set nodes_to_delete [lsort -integer -unique $nodes_to_delete] ; # We reorder the list and remove repeated nodes
		        foreach node_id $nodes_to_delete {
		            set gid_info [GiD_Info list_entities nodes $node_id]
		            if {![DEM::write::GetNodeHigherentities $node_id]} { ; # if this node does not have higher entities
		                GiD_Mesh delete node $node_id ; #delete the nodes of the element as long as it does not have higher entities
		            }
		        }
		        set point_node_ids [GiD_EntitiesGroups get $cgroupid nodes] ; # This list exists only for groups made up of isolated points
		        foreach node_id $point_node_ids {
		            if {![DEM::write::GetNodeHigherentities $node_id]} {
		                if {$probldistr == "NormalDistribution"} {
		                    set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		                } else {
		                    set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		                }
		                if {$ndime == "3D"} {
		                    set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		                } else {
		                    set new_element_id [GiD_Mesh create element append circle 1 $node_id $final_elem_radius 0 0 1] ; # We assume the 2D problem is contained in the XY plane
		                }
		                set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
		                foreach container_group $list_of_groups_containing_this_elem {
		                    GiD_EntitiesGroups assign $container_group elements $new_element_id
		                }
		            }
		        }
		        set extra_nodes [GiD_EntitiesGroups get $cgroupid nodes]
		        foreach node_id $extra_nodes {
		            if {![DEM::write::GetNodeHigherentities $node_id]} {
		                GiD_Mesh delete node $node_id
		            }
		        }
		    } elseif {$use_fem_to_dem == "AttheNodes"} {
		        # We first delete the elements (lines, triangles, quadrilaterals, tetraedra or hexahedra) of this group,
		        # but not their nodes, which will be used for creating the new sheres
		        GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements]
		        foreach node_id [GiD_EntitiesGroups get $cgroupid nodes] {
		            if {$probldistr == "NormalDistribution"} {
		                set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            } else {
		                set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            }
		            if {$ndime == "3D"} {
		                set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            } else {
		                set new_element_id [GiD_Mesh create element append circle 1 $node_id $final_elem_radius 0 0 1] ; # We assume the 2D problem is contained in the XY plane
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            }

		            set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
		            foreach container_group $list_of_groups_containing_this_elem {
		                GiD_EntitiesGroups assign $container_group elements $new_element_id
		            }
		        }

		        if {[lsearch $cohesive_groups_list $cgroupid] == -1} {
		            GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
		        }

		    } elseif {$use_fem_to_dem == "AtBothNodesAndCentroids"} {
		        set nodes_to_delete [list]
		        set element_ids [GiD_EntitiesGroups get $cgroupid elements] ; # We get the ids of all the elements in cgroupid

		        foreach element_id $element_ids { ; # Here we loop on each of the elements by id
		            if {$ndime == "3D"} {
		                set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end] ; # We get the nodes of the element
		            } else {
		                set element_nodes [lrange [GiD_Mesh get element $element_id] 3 end]
		            }
		            lappend nodes_to_delete {*}$element_nodes ; # We add those nodes to the nodes_to_delete list
		            if {$probldistr == "NormalDistribution"} {
		                set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            } else {
		                set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            }
		            set node_id [GiD_Mesh create node append [DEM::write::GetElementCenter $element_id]] ; # We create a new node starting from the center of the given element

		            if {$ndime == "3D"} {
		                set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            } else {
		                set new_element_id [GiD_Mesh create element append circle 1 $node_id $final_elem_radius 0 0 1] ; # We assume the 2D problem is contained in the XY plane
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            }

		            foreach container_group [GiD_EntitiesGroups entity_groups elements $element_id] { ; # We get the list of groups to which the element with id $element_id belongs
		                GiD_EntitiesGroups assign $container_group elements $new_element_id ; # We assign the element with id $new_element_id to each of the groups in the loop
		            }
		        }

		        GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type hexahedra] ; # TODO done again at the end?
		        GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type tetrahedra] ; # TODO done again at the end?

		        foreach node_id [GiD_EntitiesGroups get $cgroupid nodes] {
		            if {$probldistr == "NormalDistribution"} {
		                set final_elem_radius [DEM::write::NormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            } else {
		                set final_elem_radius [DEM::write::LognormalDistribution $element_radius $standard_deviation $min_radius $max_radius]
		            }
		            if {$ndime == "3D"} {
		                set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            } else {
		                set new_element_id [GiD_Mesh create element append circle 1 $node_id $final_elem_radius 0 0 1] ; # We assume the 2D problem is contained in the XY plane
		                lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		            }

		            set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
		            foreach container_group $list_of_groups_containing_this_elem {
		                GiD_EntitiesGroups assign $container_group elements $new_element_id
		            }
		        }

		        if {[lsearch $cohesive_groups_list $cgroupid] == -1} {
		            GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
		        }

		    }
		} else {
		    # 2D to 3D algorithm
		    lassign [lindex [GiD_Info Mesh elements Circle -array] 0] type element_ids element_nodes element_materials element_radii
		    foreach element_id $element_ids element_node [lindex $element_nodes 0] element_radius $element_radii {
		        set element_info($element_id) [list $element_node $element_radius]
		    }
		    set element_list [GiD_EntitiesGroups get $cgroupid elements]
		    foreach element_id $element_list {
		        lassign $element_info($element_id) element_node element_radius
		        lappend group_nodes($cgroupid) $element_node
		        lappend group_radius($cgroupid) $element_radius
		    }

		    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements]
		    foreach node_id $group_nodes($cgroupid) radius $group_radius($cgroupid) {
		        set final_elem_radius $radius
		        set new_element_id [GiD_Mesh create element append sphere 1 $node_id $final_elem_radius] ; # We create a new sphere element starting from the previous node and obtain its id
		        lappend list_of_elements_to_add_to_skin_sphere_group {*}$new_element_id
		        set list_of_groups_containing_this_elem [GiD_EntitiesGroups entity_groups nodes $node_id]
		        foreach container_group $list_of_groups_containing_this_elem {
		            GiD_EntitiesGroups assign $container_group elements $new_element_id
		        }
		    }

		    if {[lsearch $cohesive_groups_list $cgroupid] == -1} {
		        GiD_EntitiesGroups assign SKIN_SPHERE_DO_NOT_DELETE elements $list_of_elements_to_add_to_skin_sphere_group
		    }
		}
	    }
	    lappend final_list_of_isolated_nodes {*}[lindex [GiD_EntitiesGroups get $cgroupid all_mesh] 0]

	    DEM::write::Delete_Unnecessary_Elements_From_Mesh $cgroupid
	}
    }

    DEM::write::Cleaning_Up_Skin_And_Removing_Isolated_Nodes $final_list_of_isolated_nodes

    DEM::write::Destroy_Skin_Sphere_Group $KPriv(what_dempack_package) ; # Getting rid of the SKIN_SPHERE_DO_NOT_DELETE group when in discontinuum or swimming

    return $fail
}

proc DEM::write::Delete_Unnecessary_Elements_From_Mesh {cgroupid} {

    #GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid nodes]
    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type linear]
    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type triangle]
    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type quadrilateral]
    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type tetrahedra]
    GiD_Mesh delete element [GiD_EntitiesGroups get $cgroupid elements -element_type hexahedra]
}

proc DEM::write::Cleaning_Up_Skin_And_Removing_Isolated_Nodes {final_list_of_isolated_nodes} {

    GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE nodes
    #GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
    GiD_Mesh delete element [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]
    GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type linear]
    GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type triangle]
    GiD_EntitiesGroups unassign SKIN_SPHERE_DO_NOT_DELETE elements [GiD_EntitiesGroups get SKIN_SPHERE_DO_NOT_DELETE elements -element_type quadrilateral]

    foreach node_id [lsort -integer -unique $final_list_of_isolated_nodes] {
	if {![wkcf::GetNodeHigherentities $node_id]} {
	    GiD_Mesh delete node $node_id
	}
    }
}

proc DEM::write::NormalDistribution {mean standard_deviation min_rad max_rad} {
    if {$standard_deviation} {
	set max_iterations 1000 ; #set a maximun number of iterations to avoid an infinite loop
	for {set i 0} {$i < $max_iterations} {incr i} {
	    set u1 [::tcl::mathfunc::rand]
	    set u2 [::tcl::mathfunc::rand]
	    #set distribution [expr {$mean + $standard_deviation * sqrt(-2.0 * log($u1)) * cos(6.28318530717958647692 * $u2)}]
	    set distribution [math::statistics::random-normal $mean $standard_deviation 1] ; # We use the math::statistics library instead
	    if {$distribution > $min_rad && $distribution < $max_rad} {
		return $distribution
	    }
	}
	error "wkcf::NormalDistribution failed after $max_iterations iterations. mean=$mean std_dev=$standard_deviation min_rad=$min_rad max_rad=$max_rad"
    }
    return $mean
}

proc DEM::write::LognormalDistribution {mean standard_deviation min_rad max_rad} {
    if {$standard_deviation} {
	set log_min [expr log($min_rad)]
	set log_max [expr log($max_rad)]
	set NormalMean [expr {log($mean * $mean / sqrt($standard_deviation * $standard_deviation + $mean * $mean))}]
	set NormalStdDev [expr sqrt(log(1.0 + $standard_deviation * $standard_deviation / ($mean * $mean)))]
	return [expr exp([DEM::write::NormalDistribution $NormalMean $NormalStdDev $log_min $log_max])]
    }
    return $mean
}

proc DEM::write::Destroy_Skin_Sphere_Group {what_dempack_package} {
    if {$what_dempack_package eq "G-DEMPack"} {
	if [GiD_Groups exists SKIN_SPHERE_DO_NOT_DELETE] {
	    GiD_Groups delete SKIN_SPHERE_DO_NOT_DELETE
	    GidUtils::EnableGraphics
	    GidUtils::UpdateWindow GROUPS
	    GidUtils::DisableGraphics
	}
    }
}

proc ::wkcf::GetNodeHigherentities {node_id} {
    set node_data [GiD_Info list_entities nodes $node_id]
    if {![regexp {HigherEntity: ([0-9]+)} $node_data dummy higherentity]} {
	set higherentity 9999; #the node does not exist, return > 0 to not delete it
    }
    return $higherentity
}