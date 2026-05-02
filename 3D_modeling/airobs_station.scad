/* ==============================================================================
 * AIR OBSERVATORY PROJECT
 * 3D Modeling - Air Quality Mini Stations
 * 
 * This file contains the parametric modeling of the modular Stevenson screen 
 * (weather shield), including enclosures for sensors (SHT30, PM2.5) and a camera, 
 * designed for the Air Observatory project's mini monitoring stations.
 *
 * LICENSE: GNU General Public License v3.0 (GPLv3)
 * This program is free software: you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the 
 * Free Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 * ============================================================================== */

// Global resolution for rendering curved geometries (arcs, cylinders, spheres)
$fn = 100;

// -----------------------------------------------------
// PRINTED CIRCUIT BOARD (CAMERA PCB) PARAMETERS
// -----------------------------------------------------
pcb_width = 42.1;
pcb_height = 58.5;
pcb_thickness = 1.6;

internal_offset_y = -15;
straight_wall_thickness = 1;

// -----------------------------------------------------
// FASTENING AND ROD PARAMETERS
// -----------------------------------------------------
rod_type = 4; // M4 threaded rod
clearance_hole_radius = (rod_type / 2) + 0.25; // 0.5mm total diametrical clearance

// Conditional calculation to define the nut recess radius based on rod type
female_recess_radius = (rod_type == (5/16) * 25.4) ? 8 : (rod_type == 6) ? 7 : (rod_type == 4) ? 5 : (rod_type == 3) ? 4 : 7;

// Radial distance from the origin to the fastening holes
rod_hole_distance = 41;

// -----------------------------------------------------
// CAMERA DOME (TOP ENCLOSURE) PARAMETERS
// -----------------------------------------------------
clearance = 0.6;                 // General 3D printing tolerance
wall_thickness = 1.4;            // Dome wall thickness
rear_connector_space = 25;       // Depth reserved for connectors on the back of the PCB
camera_hole_diameter = 17.3;     // Frontal hole diameter for the camera lens
lens_clearance = 0.5;            // Safety gap between lens and inner dome wall

front_cut_adjustment = 3 - 3.4;  // Calibration for the dome's front cut plane
bottom_skirt_extension = 0;      // Additional length for the dome's cylindrical base

side_guide_depth = 6;            // Depth of the side rails holding the PCB
side_fit = 3.5 - 2.2;            // Fit adjustment for sliding the PCB into the rails
slot_clearance = 0.15;           // Rail slot thickness tolerance
side_clearance = 0.2;            // Rail width tolerance

pcb_z_offset = -4;               // Z-axis position of the PCB relative to the dome origin
camera_z_offset_on_pcb = 13.6;   // Z-axis position of the lens center relative to the PCB base

dome_y_offset = -5;              // Y-axis dome shift to balance the center of gravity

// Dynamic calculations for the dome's external geometry
dome_radius = (pcb_height/2) + clearance + wall_thickness + 2;
cylindrical_skirt_length = (pcb_height/2) - pcb_z_offset + clearance + bottom_skirt_extension;

// Calculations for front and rear bounds to determine asymmetry and center offset
front_face_abs_y = -(pcb_thickness/2 + 22.5 + lens_clearance) - front_cut_adjustment;
total_front_advance_y = pcb_thickness/2 + 22.5 + 2.3;
total_rear_advance_y = pcb_thickness/2 + rear_connector_space;
offset_y = (total_rear_advance_y - total_front_advance_y) / 2; // Y shift for asymmetric PCB accommodation

// -----------------------------------------------------
// LEGACY CARRIAGE BOLT PARAMETERS (Kept for mathematical structure)
// -----------------------------------------------------
screw_head_d = 18;
screw_rod_d = 7.9375;
screw_length = 177.8;
screw_head_h = 4.5;
square_l = 8.1;
square_h = 4.5;

sphere_r = (pow(screw_head_h, 2) + pow(screw_head_d/2, 2)) / (2 * screw_head_h);
z_offset = sphere_r - screw_head_h;

// -----------------------------------------------------
// WEATHER SHIELD RINGS (LOUVERS) PARAMETERS
// -----------------------------------------------------
louver_ext_d = 120; // Total external diameter of the louver
louver_int_d = 96;  // Internal diameter (hollow area for airflow)
louver_wall = 2;    // Louver solid wall thickness
louver_angle = 50;  // Inclination angle to block sunlight and allow ventilation

// Trigonometric calculation of louver height based on rim width and angle
louver_h = ((louver_ext_d - louver_int_d) / 2) * tan(louver_angle);

// Z-axis translation step used to generate the stacking array
stacking_distance = louver_h - 2;

// -----------------------------------------------------
// VISUAL HARDWARE COMPONENTS MODULES
// -----------------------------------------------------

// Generates the M4 threaded rod representation for visualization
module threaded_rod_m4() {
    color("silver")
    translate([0, 0, -15])
        cylinder(h=150, d=4, $fn=50);
}

// Generates an M4 hex nut with top and bottom chamfers
module hex_nut() {
    Waf = 12.6; // Width across flats
    Height = 6.75;
    Hole_Dia = 8.5;
    Vertex_Radius = Waf / sqrt(3);
    Chamfer_Factor = 0.92;
    
    color("silver")
    difference() {
        difference() {
            linear_extrude(height = Height, center = true)
                circle(r = Vertex_Radius, $fn = 6);
            cylinder(h = Height + 1, d = Hole_Dia, center = true);
        }
        translate([0, 0, Height / 2])
            rotate_extrude()
                translate([Vertex_Radius * Chamfer_Factor, 0, 0])
                    intersection() {
                        square(size = [Height, Height], center = false);
                        circle(r = Height);
                    }
        translate([0, 0, -Height / 2])
            mirror([0, 0, 1])
            rotate_extrude()
                translate([Vertex_Radius * Chamfer_Factor, 0, 0])
                    intersection() {
                        square(size = [Height, Height], center = false);
                        circle(r = Height);
                    }
    }
}

// Generates the PCB mockup, front cylindrical lens, and reserved rear space
module pcb() {
    rotate([90, 0, 0])
    color("red")
    cube([pcb_width, pcb_height, pcb_thickness], center = true);
    
    translate([0, -(pcb_thickness/2 + 22.5-3.7), camera_z_offset_on_pcb])
    rotate([90, 0, 0])
    cylinder(h=2.3, d=7, center= true);
    
    color("blue", 0.5)
    translate([0, (pcb_thickness/2) + (rear_connector_space/2), -10])
    cube([pcb_width - 10, rear_connector_space, 15], center = true);
}

// -----------------------------------------------------
// 2D AUXILIARY GEOMETRY MODULES
// -----------------------------------------------------

// Returns an elliptical profile through X and Y scaling
module ellipse(rx, ry) {
    scale([rx, ry, 1])
        circle(r = 1);
}

// Returns a shape with rounded edges and flat center area (capsule/slot)
module oblong(centers_distance, radius) {
    hull() {
        translate([-centers_distance/2, 0, 0])
            circle(r=radius, $fn=50);
        translate([centers_distance/2, 0, 0])
            circle(r=radius, $fn=50);
    }
}

// -----------------------------------------------------
// 3D PRINTED CONSTRUCTION MODULES
// -----------------------------------------------------

// Generates the main camera housing body (spherical top dome with cylindrical skirt)
module dome_enclosure() {
    rel_front_face_y = front_face_abs_y - offset_y;
    rel_front_face_y_inner = rel_front_face_y + wall_thickness;
    rel_camera_hole_y = -(pcb_thickness/2 + 22.5) - offset_y;
    z_camera_hole = camera_z_offset_on_pcb + pcb_z_offset;
    c_size = dome_radius * 4;
    
    // Submodule: creates the solid outer matrix (sphere + cylinder) cut at the Z plane
    module solid_profile(radius, bottom_extension = 0) {
        union() {
            difference() {
                sphere(r=radius, $fn=100);
                translate([0, 0, -radius]) cube([radius*3, radius*3, radius*2], center=true);
            }
            overlap = 0.1;
            translate([0, 0, -cylindrical_skirt_length - bottom_extension])
                cylinder(r=radius, h=cylindrical_skirt_length + bottom_extension + overlap, $fn=100);
        }
    }
    
    // Submodule: creates the inner negative to subtract and form the dome walls
    module internal_volume() {
        difference() {
            solid_profile(dome_radius - wall_thickness, 1);
            translate([0, rel_front_face_y_inner - c_size/2, 0])
                cube([c_size, c_size, c_size], center=true);
        }
    }
    
    union() {
        difference() {
            difference() {
                solid_profile(dome_radius, 0);
                translate([0, rel_front_face_y - c_size/2, 0])
                    cube([c_size, c_size, c_size], center=true);
            }
            internal_volume();
            translate([0, rel_camera_hole_y+5, z_camera_hole])
                rotate([90, 0, 0])
                cylinder(h=wall_thickness +20, d=camera_hole_diameter, center=true);
        }
        
        // Generates the internal Z-axis rails for PCB sliding fit
        intersection() {
            guide_z_top = pcb_z_offset + (pcb_height / 2);
            guide_z_bottom = -cylindrical_skirt_length;
            dynamic_guide_height = guide_z_top - guide_z_bottom;
            guides_z_center = guide_z_bottom + (dynamic_guide_height / 2);
            block_x = dome_radius;
            pos_x = (pcb_width / 2) + (block_x / 2) - side_fit;
            
            translate([0, -offset_y, guides_z_center]) {
                difference() {
                    union() {
                        translate([pos_x, 0, 0]) cube([block_x, side_guide_depth, dynamic_guide_height], center=true);
                        translate([-pos_x, 0, 0]) cube([block_x, side_guide_depth, dynamic_guide_height], center=true);
                    }
                    cube([pcb_width + (side_clearance * 2), pcb_thickness + slot_clearance, dynamic_guide_height + 2], center=true);
                    translate([0, 0, -(dynamic_guide_height/2)])
                        rotate([45, 0, 0])
                        cube([pcb_width + (side_clearance * 2), 8, 8], center=true);
                }
            }
            internal_volume();
        }
    }
}

// Generates the anchor body and internal shielding for the PM2.5 sensor
module bottom_housing(ring_diam, clearance_radius) {
    // Bottom box containing exhaust inlets and optical sensor hole
    difference(){
        cube([50,39,7], center=true);
        translate([-12.5,7.0,0]) cylinder(9, d= 20.5, center=true);
        translate([12.9, 7.50, 0]) cube([14, 9.4, 9], center = true);
    }
    // Main hollow box centered on intersecting X and Y rods
    translate([0,0,-3])
        difference(){
            union() {
                cube([50,39,12], center=true);
                cube([ring_diam, 17, 8], center=true);
                cube([17, ring_diam, 8], center=true);
            }
            cube([48.5,36.9,13], center=true);
            
            // Clears the rod matrices at the four poles to avoid conflict with ring holes
            for (angle = [0, 90, 180, 270]) {
                rotate([0, 0, angle]) {
                    translate([0, rod_hole_distance, 0])
                        cylinder(h=20, r=clearance_radius, center=true, $fn=50);
                }
            }
        }
}

// Generates the mount and duct for the SHT30 temperature sensor
module sht30_mount(ring_diam, clearance_radius) {
    difference() {
        union() {
            cylinder(h=4, d=30, center=true, $fn=100);
            rotate([0, 0, 180]) cube([ring_diam, 17, 4], center=true);
            rotate([0, 0, -90]) cube([ring_diam, 17, 4], center=true);
        }
        cylinder(h=6, d=13, center=true, $fn=100);
        translate([0, 0, -2]) cylinder(h=4, d=18, center=true, $fn=50);
        
        for (angle = [0, 90, 180, 270]) {
            rotate([0, 0, angle]) {
                translate([0, rod_hole_distance, 0])
                    cylinder(h=20, r=clearance_radius, center=true, $fn=50);
            }
        }
    }
}

// Generates the 360-degree revolved profile of the conical weather louver from a 2D polygon
module louver(ext_d, int_d, wall, h) {
    rotate_extrude($fn=100) {
        polygon([
            [ext_d/2, 0],
            [(ext_d/2) - wall, 0],
            [(int_d/2) - wall, h],
            [int_d/2, h]
        ]);
    }
}

// Generates the 4 connector blocks for standard rings (with male pins below and female recesses above)
module mounting_bases(ext_d, int_d, h, hole_radius, female_radius) {
    pin_height = 2;
    print_clearance = 0.3;
    male_pin_radius = female_radius - print_clearance;
    block_width = (female_radius * 2)+1;
    block_length = 26;
    block_offset_y = 5;
    block_height = 12;
    
    difference() {
        // Addition geometry (Matrices + Pins)
        union() {
            // Rectangular blocks confined by the outer ring diameter
            intersection() {
                union() {
                    for (angle = [0, 90, 180, 270]) {
                        rotate([0, 0, angle])
                            translate([0, rod_hole_distance + block_offset_y, h - (block_height/2)])
                                cube([block_width, block_length, block_height], center=true);
                    }
                }
                rotate_extrude($fn=100) {
                    polygon([[0, 0], [ext_d/2, 0], [int_d/2, h], [0, h]]);
                }
            }
            // Male pins projecting from the bottom face, with a straight external cut ("D" shape)
            for (angle = [0, 90, 180, 270]) {
                rotate([0, 0, angle]) {
                    difference() {
                        translate([0, rod_hole_distance, h - block_height - pin_height])
                            cylinder(h=pin_height, r=male_pin_radius, $fn=50);
                        translate([0, rod_hole_distance + male_pin_radius, h - block_height - pin_height + 1])
                            cube([male_pin_radius * 3, male_pin_radius, pin_height + 2], center=true);
                    }
                }
            }
        }
        
        // Subtraction: clearance holes and top female recesses
        for (angle = [0, 90, 180, 270]) {
            rotate([0, 0, angle]) {
                translate([0, rod_hole_distance, h - block_height - pin_height - 1])
                    cylinder(h=block_height + pin_height + 2, r=hole_radius, $fn=50);
                translate([0, rod_hole_distance, h - pin_height-2.5])
                    cylinder(h=pin_height + 3, r=female_radius, $fn=50);
            }
        }
    }
}

// Generates the EXCLUSIVE connector blocks for the base ring (no bottom pins, slotted for metal mount)
module base_ring_mounting_bases(ext_d, int_d, h, hole_radius, female_radius) {
    block_width = (female_radius * 2)+8;
    block_length = 26;
    block_offset_y = 5;
    block_height = 15;
    
    difference() {
        // Solid matrix restricted to outer circumference
        intersection() {
            union() {
                for (angle = [0, 90, 180, 270]) {
                    rotate([0, 0, angle])
                        translate([0, rod_hole_distance + block_offset_y, h - (block_height/2)])
                            cube([block_width, block_length, block_height], center=true);
                }
            }
            rotate_extrude($fn=100) {
                polygon([[0, 0], [ext_d/2, 0], [int_d/2, h], [0, h]]);
            }
        }
        
        // Structural fastening subtractions
        for (angle = [0, 90, 180, 270]) {
            rotate([0, 0, angle]) {
                // Top female recess for the upper ring to fit in
                translate([0, rod_hole_distance, h - 2 - 2.5])
                    cylinder(h=5, r=female_radius, $fn=50);
                    
                // Clearance hole for the M4 threaded rod
                translate([0, rod_hole_distance, h - block_height - 1])
                    cylinder(h=block_height + 2, r=hole_radius, $fn=50);
                    
                // 2.1mm rectangular slot at the base to intersect with the metal bracket
                translate([0, rod_hole_distance + 3.5, h - 13])
                    cube([block_width + 5, 2.1, 13], center=true);
            }
        }
    }
}

// Combines the standard outer louver with male/female mounting blocks
module standard_ring(ext_d, int_d, h) {
    louver(ext_d, int_d, louver_wall, h);
    mounting_bases(ext_d, int_d, h, clearance_hole_radius, female_recess_radius);
}

// Combines the outer louver with modified bases to act as the initial anchor for the metal bracket
module base_ring(ext_d, int_d, h) {
    louver(ext_d, int_d, louver_wall, h);
    base_ring_mounting_bases(ext_d, int_d, h, clearance_hole_radius, female_recess_radius);
}

// Standard ring modified with the internal mount coupling for the SHT30 sensor
module sht30_ring(ext_d, int_d, h, wall) {
    standard_ring(ext_d, int_d, h);
    intersection() {
        translate([0, 0, h - 2]) sht30_mount(ext_d, female_recess_radius);
        rotate_extrude($fn=100) {
            polygon([[0, 0], [(ext_d/2) - wall, 0], [(int_d/2) - wall, h], [0, h]]);
        }
    }
}

// Standard ring modified with the coupling for the PM2.5 particle sensor enclosure
module pm25_ring(ext_d, int_d, h, wall) {
    standard_ring(ext_d, int_d, h);
    intersection() {
        translate([0, 0, h - 1]) rotate([0,0,0]) bottom_housing(ext_d, female_recess_radius);
        rotate_extrude($fn=100) {
            polygon([[0, 0], [(ext_d/2) - wall, 0], [(int_d/2) - wall, h], [0, h]]);
        }
    }
}

// Generates the continuous circular floor that closes the shield chamber and supports the top camera dome
module dome_base(base_thickness, int_d) {
    rel_front_face_y = front_face_abs_y - offset_y;
    rel_front_face_y_inner = rel_front_face_y + wall_thickness;
    c_size = dome_radius * 4;
    
    difference() {
        cylinder(d=int_d+1, h=base_thickness, $fn=100);
        
        // Generates clearance holes in the continuous plate for the rods to pass through
        for (angle = [0, 90, 180, 270]) {
            rotate([0, 0, angle]) {
                translate([0, rod_hole_distance, -1])
                    cylinder(h=base_thickness + 2, r=clearance_hole_radius, $fn=50);
            }
        }
        
        // Deep rectangular subtraction corresponding to the camera module fit offset
        translate([0, offset_y + dome_y_offset, -1]) {
            difference() {
                cylinder(r=dome_radius - wall_thickness, h=base_thickness + 2, $fn=100);
                translate([0, rel_front_face_y_inner - c_size/2, 0])
                    cube([c_size, c_size, base_thickness * 4], center=true);
            }
        }
    }
}

// Hierarchical grouping of the shield's upper floor parts (Base + Dome + PCB)
module camera_top_module(int_d) {
    base_thickness = 2;
    translate([0, 0, 0])
        dome_base(base_thickness, int_d);
    translate([0, offset_y + dome_y_offset, base_thickness + cylindrical_skirt_length])
        dome_enclosure();
        
    // PCB is currently deactivated via '//', if needed, remove the comments from the two lines below:
    //translate([0, dome_y_offset, base_thickness + cylindrical_skirt_length + pcb_z_offset])
      //  pcb();
}

// -----------------------------------------------------
// GLOBAL MODEL STACKING ARRAY (VISUALIZATION)
// -----------------------------------------------------

// Level 0: Base connected to the bracket
// translate([0, 0, 0])
    base_ring(louver_ext_d, louver_int_d, louver_h);

// Level 1: SHT30 sensor module
// translate([0, 0, stacking_distance * 1])
//    sht30_ring(louver_ext_d, louver_int_d, louver_h, louver_wall);

// Levels 2 to 3: Spacers
// translate([0, 0, stacking_distance * 2])
//    standard_ring(louver_ext_d, louver_int_d, louver_h);
// translate([0, 0, stacking_distance * 3])
//    standard_ring(louver_ext_d, louver_int_d, louver_h);

// Level 4: Particulates module
// translate([0, 0, stacking_distance * 4])
//    pm25_ring(louver_ext_d, louver_int_d, louver_h, louver_wall);

// Level 5: Spacer
// translate([0, 0, stacking_distance * 5])
//    standard_ring(louver_ext_d, louver_int_d, louver_h);

// Level 6: Camera roof module
// translate([0, 0, stacking_distance * 6])
//    camera_top_module(louver_int_d);