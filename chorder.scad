// TODO: Whole thing should be much more comprehensively commented
// TODO: test object should have contacts at weird angles
// TODO: test object should include connector_positive/connector_negative
// TODO: model should echo() absolute positions of buttons, relative to some
//       known point (connection point?)


/*****************************************************************************/
/* Likely calibration properties                                             */
/*****************************************************************************/

// finger_measurements
//
// For the below, the "first joint" (joint 0) is the one at the base of the
// finger. Most people thus have joints 0, 1 and 2 on their four fingers, and
// joints 0 and 1 on their thumb (I'm not exception).
//
// The "first segment" (segment 0) thus is between joint 0 and joint 1, etc,
// until segment 2, which ends at the tip of the finger (segment 1 in the case
// of a thumb).
//
// Generally, these are measured when joints are bent 90 degrees.
//
// E.g. to measure segment 0 on pinky, you'd clench your fist and look at it
// from below. That way, joint0 and joint1 on pinky will be at an angle of at
// least 90 degrees. Then you put a caliper on those two pinky joints.
// 
// (It gets more finger-yoga-like to do this with other joints. You'll probably
// have to use another hand to hold the joint in a slightly overstretched
// position. Or take a guess.)
pinky_segment_lengths  = [ 53,  32, 38 ];
ring_segment_lengths   = [ 65,  40, 41 ];
middle_segment_lengths = [ 69,  44, 41 ];
index_segment_lengths  = [ 65,  39, 41 ];
thumb_segment_lengths  = [ 54,  40 ];

// Radii of each finger:
pinky_radius  =  7.5;
ring_radius   =  9.0;
middle_radius = 10.0;
index_radius  = 10.0;
thumb_radius  = 11.0;

// Angles at joint 0, joint 1 and joint 2, for a "comfortably glove-shaped" hand:
pinky_angles  = [20,37,33];
ring_angles   = [20,60,15];
middle_angles = [15,60,10];
index_angles  = [20,30,10];
thumb_angles  = [0,00];

// Almost-guesstimate: for a fingers-stretched hand, where are the joint 0's?
//
pinky_joint0_offset  = [ 110, -25,-15];
ring_joint0_offset   = [  89, -10,-10];
middle_joint0_offset = [  64,   0,  0];
index_joint0_offset  = [  32,  -2,  0];
thumb_joint0_offset  = [   5, -50,-40];

wristaxis_thumbside_upper_offset  = [  37, -80,-15];
wristaxis_pinkyside_upper_offset  = [  97, -80,-15];
wristaxis_radius = 20;

// four fingers: rotation around y axis:
pinky_joint0_rotation  =  17;
ring_joint0_rotation   =   9;
middle_joint0_rotation =  -3;
index_joint0_rotation  = -10;
// thumb: rotation around x axis:
thumb_joint0_rotation  = -110;

// LiPo battery measurements:

lipo_compartment_wdh = [26,44,11];


// MCU related measurements:

// (Clearance in the height dimension has to be fairly generous if you're using
// Dupont cables.)
mcu_clearance_wdh = [51.5,23.5,30];
mcu_wall_w = 1.5;

// the module used to subtract clearance for your particular mcu:
module mcu_clearance_box()
{
  // This is for an Adafruit Feather 32u4 BLE
  //
  // https://learn.adafruit.com/adafruit-feather-32u4-bluefruit-le/overview
  usb_clear_wh = [10.5,10];
  usb_vertical_offset = -1.5;
  cube(mcu_clearance_wdh);

  // USB charging cable entry:
  translate([
    mcu_clearance_wdh[0]-0.01,
    mcu_clearance_wdh[1]/2-usb_clear_wh[0]/2,
    usb_vertical_offset])
    cube([frame_radius+0.02,usb_clear_wh[0],usb_clear_wh[1]+0.01]);

  // Battery connector (in reality from 8 to 14 mm from the end of board):
  translate([
    mcu_clearance_wdh[0]-5-10,
    -frame_radius,
    1])
    cube([10,2*frame_radius,5+0.01]);
}

// Elastic band width:

elastic_band_w = 20;
// measured as compressed, if relevant:
elastic_band_thickness = 1;
elastic_band_clearing_w = 22;
elastic_band_wall_w = 3;

button_hole_overdimension_factor = 1.15;

/*****************************************************************************/
/* Less-likely calibration properties                                        */
/*****************************************************************************/



// real m3 radius:
m3_radius = 1.5;
// so that an m3 bolt can be passed through without too much effort:
m3_clear_radius = 1.7;

m3_bolt_visualisation_height = 26;

m3_head_radius = 3; // from memory
m3_head_clear_radius = 3.2; // from memory
m3_nut_clear_radius = 3.4; // When creating $fn=6 cutouts for these
m3_nut_height = 2; // actual height (for visualisation)
m3_nut_clear_height = 4; // When creating $fn=6 cutouts for these
m3_head_height = 2; // from memory
m3_nut_holder_wall_w = 1;


connector_depth = 2;

// how much to depress (in the z direction) contact_{positive,negative} given
// that the contact point is at z=0.
contact_z_depress = 15;
// how much depression of spring before electrical contact is made:
contact_clearance = 2;
// 0.3mm wire diameter 10 mm high 6mm outer diameter springs:
// https://www.aliexpress.com/item/33050149067.html
spring_radius = 3;
spring_height = 10;

// how far down (perspective of joint1 on the thumb) the connection point is placed:
thumb_connection_point_translation_distance = 2*thumb_radius;

// the girth of the riggers that make up the most of the finger mounts
frame_radius = 5;

// Derive coordinates and rotation vectors:

// Helper functions {{{

// These helper functions calculate the coordinate following a segment, as if
// *_joint0_rotation didn't exist (it can be compensated for, later on).
function x_coord_for(startvec,angle,segment,radius) =
  startvec[0] ; // always same, given no _joint0 rotation.
function y_coord_for(startvec,angle,segment,radius) =
  startvec[1] + cos(angle)*(segment-2*radius);
function z_coord_for(startvec,angle,segment,radius) =
  startvec[2] + sin(-angle)*(segment-2*radius);

function sum(list,i=0) = i<len(list)-1 ? list[i] + sum(list,i+1) : list[i];
assert(sum([ 4, 5, 3]) == 12);
assert(sum([ 4, 1, -1]) == 4);

function rotate_coord(coord,joint0_rotation,relative_to_joint0_offset) =
  [
    // have hypotenuse and angle, want opposite:
    relative_to_joint0_offset[0]-sin(joint0_rotation)*(relative_to_joint0_offset[2]-coord[2]),
    coord[1], // remains the same when rotating around y axis
    // have hypotenuse and angle, want adjacent:
    relative_to_joint0_offset[2]-cos(joint0_rotation)*(relative_to_joint0_offset[2]-coord[2])
  ];

function coord_for(startvec,angle,segment,radius) =
  [
    x_coord_for(startvec,angle,segment,radius),
    y_coord_for(startvec,angle,segment,radius),
    z_coord_for(startvec,angle,segment,radius)
  ];

// Returns a euler rotation 3-tuple that can be used to rotate something in the
// direction of the vector given:
function rotation_of_vector(v) =
  // {{{
  // Due to OpenSCAD function syntax, the below cannot have interim variables.
  // This was a previous calculation, for reference:
  //
  // rotation_upwards = atan(v[2])/sqrt(pow(v[0],2)+pow(v[1],2)));
  // tangent = (v[1])/(v[0]);
  // rotation_in_plane = atan(tangent) + (0 > (v[0]) ? 180 : 0);
  [
    0,
    90-atan((v[2])/sqrt(pow(v[0],2)+pow(v[1],2))),
    // possible corner case: what about _minus_ infinity?
    (is_num(atan(v[1]/v[0])) ? atan(v[1]/v[0]) + (0 > (v[0]) ? 180 : 0) : 90)
  ];
  // }}}

// Applies euler rotation 3-tuple rotations by way of matrix multiplication.
// This function's output is multiplied onto a vector of [0,0,length].
function rotation_for_euler_rotations(a) =
    [[cos(a[2]),-sin(a[2]),0],[sin(a[2]),cos(a[2]),0],[0,0,1]]
    * [[cos(a[1]),0,sin(a[1])],[0,1,0],[-sin(a[1]),0,cos(a[1])]]
    * [[1,0,0],[0,cos(a[0]),-sin(a[0])],[0,sin(a[0]),cos(a[0])]];

// }}}

// Assign {pinky,ring,middle,index,thumb}_{coords,rotation} {{{

// For pinky {{{
_pinky_coord_1 = coord_for(pinky_joint0_offset,sum([for (i=[0:0]) pinky_angles[i]]),pinky_segment_lengths[0],pinky_radius);
_pinky_coord_2 = coord_for(_pinky_coord_1,     sum([for (i=[0:1]) pinky_angles[i]]),pinky_segment_lengths[1],pinky_radius);
_pinky_coord_3 = coord_for(_pinky_coord_2,     sum([for (i=[0:2]) pinky_angles[i]]),pinky_segment_lengths[2],pinky_radius);

pinky_coords = [
  rotate_coord(pinky_joint0_offset,pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_1,     pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_2,     pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_3,     pinky_joint0_rotation,pinky_joint0_offset)
];
pinky_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) pinky_angles[j] ? -pinky_angles[j] : 0]),
    pinky_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For ring {{{
_ring_coord_1 = coord_for(ring_joint0_offset,sum([for (i=[0:0]) ring_angles[i]]),ring_segment_lengths[0],ring_radius);
_ring_coord_2 = coord_for(_ring_coord_1,     sum([for (i=[0:1]) ring_angles[i]]),ring_segment_lengths[1],ring_radius);
_ring_coord_3 = coord_for(_ring_coord_2,     sum([for (i=[0:2]) ring_angles[i]]),ring_segment_lengths[2],ring_radius);

ring_coords = [
  rotate_coord(ring_joint0_offset,ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_1,     ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_2,     ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_3,     ring_joint0_rotation,ring_joint0_offset)
];
ring_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) ring_angles[j] ? -ring_angles[j] : 0]),
    ring_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For middle {{{
_middle_coord_1 = coord_for(middle_joint0_offset,sum([for (i=[0:0]) middle_angles[i]]),middle_segment_lengths[0],middle_radius);
_middle_coord_2 = coord_for(_middle_coord_1,     sum([for (i=[0:1]) middle_angles[i]]),middle_segment_lengths[1],middle_radius);
_middle_coord_3 = coord_for(_middle_coord_2,     sum([for (i=[0:2]) middle_angles[i]]),middle_segment_lengths[2],middle_radius);

middle_coords = [
  rotate_coord(middle_joint0_offset,middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_1,     middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_2,     middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_3,     middle_joint0_rotation,middle_joint0_offset)
];
middle_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) middle_angles[j] ? -middle_angles[j] : 0]),
    middle_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For index {{{
_index_coord_1 = coord_for(index_joint0_offset,sum([for (i=[0:0]) index_angles[i]]),index_segment_lengths[0],index_radius);
_index_coord_2 = coord_for(_index_coord_1,     sum([for (i=[0:1]) index_angles[i]]),index_segment_lengths[1],index_radius);
_index_coord_3 = coord_for(_index_coord_2,     sum([for (i=[0:2]) index_angles[i]]),index_segment_lengths[2],index_radius);

index_coords = [
  rotate_coord(index_joint0_offset,index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_1,     index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_2,     index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_3,     index_joint0_rotation,index_joint0_offset)
];
index_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) index_angles[j] ? -index_angles[j] : 0]),
    index_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For thumb {{{
// FIXME/HACK: Using 0.5 thumb_radius to compensate for the geometry of the
// ball of the thumb.
_thumb_coord_1 = coord_for(thumb_joint0_offset,sum([for (i=[0:0]) thumb_angles[i]]),thumb_segment_lengths[0],0.5*thumb_radius);
_thumb_coord_2 = coord_for(_thumb_coord_1,     sum([for (i=[0:1]) thumb_angles[i]]),thumb_segment_lengths[1],thumb_radius);

thumb_coords = [
  rotate_coord(thumb_joint0_offset,thumb_joint0_rotation,thumb_joint0_offset),
  rotate_coord(_thumb_coord_1,     thumb_joint0_rotation,thumb_joint0_offset),
  rotate_coord(_thumb_coord_2,     thumb_joint0_rotation,thumb_joint0_offset),
];
thumb_rotation = [ for (i=[0:2])
  [
    // Ternary expression necessary to handle that there is no angle available
    // at joint2 for a thumb:
    90+sum([for (j=[0:i]) thumb_angles[j] ? -thumb_angles[j] : 0]), // always 0 when rotating in y and x axes
    thumb_joint0_rotation,
    -90,
  ],
];

// }}}

// }}}

// Calculating where the thumb connection point is {{{
thumb_connection_point = 
thumb_coords[1]+
  -thumb_connection_point_translation_distance*rotation_for_euler_rotations(thumb_rotation[1])*[0,0,1];
// }}}

// Calculating where the parts attaches to each other {{{
// Warning: inexact science at play. Technically, these points could be derived
// from observed angles between e.g. index and middle joint0's.

finger_end_connection_point_thumb = 
  0.2*index_joint0_offset+
  0.8*thumb_connection_point+
  [0,-frame_radius,0];

finger_end_connection_point_index = 
  0.6*index_joint0_offset + 
  0.4*middle_joint0_offset+
  [0,-3*connector_depth,-10-frame_radius];

finger_end_connection_point_pinky = 
  0.3*ring_joint0_offset + 
  0.7*pinky_joint0_offset+
  [0,-4*connector_depth,-8-frame_radius];

finger_end_connection_point_radius = frame_radius;

wrist_handle_connection_frame_height = 30;

body_wristaxis_thumbside_upper_offset = wristaxis_thumbside_upper_offset+[0,0,-wristaxis_radius-frame_radius];
body_wristaxis_pinkyside_upper_offset = wristaxis_pinkyside_upper_offset+[0,0,-wristaxis_radius-frame_radius];
body_wristaxis_thumbside_lower_offset = wristaxis_thumbside_upper_offset+[0,0,-wristaxis_radius-frame_radius-wrist_handle_connection_frame_height];
body_wristaxis_pinkyside_lower_offset = wristaxis_pinkyside_upper_offset+[0,0,-wristaxis_radius-frame_radius-wrist_handle_connection_frame_height];

wrist_handle_connection_point_thumb_upper = 
  body_wristaxis_thumbside_upper_offset+[0,-frame_radius,0];
wrist_handle_connection_point_thumb_lower = 
  body_wristaxis_thumbside_lower_offset+[0,-frame_radius,0];
wrist_handle_connection_point_pinky_upper = 
  body_wristaxis_pinkyside_upper_offset+[0,-frame_radius,0];
wrist_handle_connection_point_pinky_lower = 
  body_wristaxis_pinkyside_lower_offset+[0,-frame_radius,0];


// }}}

// Helper modules:

module cylinder_from_to (origin,dest,radius1,radius2)
{ // {{{
  length = sqrt(
    pow(origin[0]-dest[0],2)+
    pow(origin[1]-dest[1],2)+
    pow(origin[2]-dest[2],2)
  );

  rot = rotation_of_vector(dest-origin);

  translate(origin)
    rotate(rot)
      cylinder(r1=radius1,r2=radius2,h=length);
} // }}}

module elastic_clasp_positive()
{ // {{{
  rounding_r = 2;
  clasp_length = elastic_band_clearing_w+2*elastic_band_wall_w+2*m3_head_clear_radius+2*m3_clear_radius-2*rounding_r;

  minkowski()
  {
    cylinder(r=rounding_r,h=0.01,$fn=20);
    translate([rounding_r,rounding_r,0])
      cube([2*frame_radius-2*rounding_r,
        clasp_length-2*rounding_r,
        frame_radius]);
  }

  translate([0,0,-elastic_band_wall_w-elastic_band_thickness])
  intersection()
  {
    cube([2*frame_radius,
      clasp_length,
      elastic_band_wall_w]);
    minkowski()
    {
      sphere(rounding_r,$fn=20);
      translate([rounding_r,rounding_r,rounding_r])
        cube([2*frame_radius-2*rounding_r,
          clasp_length-2*rounding_r,
          elastic_band_wall_w-rounding_r]);
    }
  }
} // }}}

module elastic_clasp_negative()
{ // {{{
  for (offs = [0,elastic_band_clearing_w+2*m3_clear_radius])
  {
    translate([
      frame_radius,
      elastic_band_wall_w+1*m3_clear_radius+offs,
      -elastic_band_wall_w-elastic_band_thickness-0.01])
      {
        cylinder(r=m3_clear_radius,h=3*frame_radius,$fn=20);
      }

    translate([
      frame_radius,
      elastic_band_wall_w+1*m3_clear_radius+offs,
      2*frame_radius-1.3*m3_head_height])
      {
        cylinder(r=m3_head_clear_radius,h=3*frame_radius,$fn=20);
      }
  }
} // }}}

rounding_r = 2;
clasp_length = elastic_band_clearing_w+2*elastic_band_wall_w+2*m3_head_clear_radius+2*m3_clear_radius-2*rounding_r;
loose_clasp_length = clasp_length + 2*m3_head_clear_radius+2*m3_clear_radius+2*rounding_r+2*elastic_band_wall_w;

module elastic_clip_positive()
{ // {{{

  rotate([0,90,0])
  translate([-frame_radius,0,-3*frame_radius])
  minkowski()
  {
    cylinder(r=rounding_r,h=0.01,$fn=20);
    translate([rounding_r,rounding_r,0])
      cube([2*frame_radius-2*rounding_r,
        clasp_length-2*rounding_r,
        3*frame_radius]);
  }

  module clasp_together()
  {
    difference()
    {
      translate([0,0,0])
        hull()
        {
            rotate([-90,0,0])
              for (o=[0,1*frame_radius])
              translate([o,0,0])
              cylinder(r=rounding_r,h=loose_clasp_length,$fn=20);
        }
      translate([0.5*frame_radius,0,0])
      {
        translate([0,0,-frame_radius])
          {
            for (offs = [
              elastic_band_wall_w+1*m3_head_clear_radius,
              loose_clasp_length-(elastic_band_wall_w+1*m3_head_clear_radius)])
            {
              translate([
                0,
                offs,
                -elastic_band_wall_w-elastic_band_thickness-0.01])
                {
                  cylinder(r=m3_clear_radius,h=3*frame_radius,$fn=20);
                }
            }
          }
      }
    }
  }

  module clasp_one_side()
  {
    intersection()
    {
      translate([-frame_radius,0,0])
        cube([3*frame_radius,loose_clasp_length,rounding_r]);
      clasp_together();
    }
  }

  rotate([0,90,0])
    translate([0,-(loose_clasp_length-clasp_length)/2,-4*frame_radius])
    {
      clasp_one_side();

      translate([0,0,-elastic_band_thickness])
        mirror([0,0,1])
        clasp_one_side();
    }

} // }}}

module elastic_clip_negative()
{ // {{{
  rotate([0,90,0])
  translate([-frame_radius,0,-3*frame_radius])
  translate([1.2*frame_radius,-0.01,frame_radius])
    rotate([-90,0,0])
    {
      hull()
      {
        for (o=[0,frame_radius])
          translate([o,0,0])
          cylinder(r=rounding_r+1.5*elastic_band_thickness,h=0.02+clasp_length,$fn=20);
      }
    }
  rotate([0,90,0])
  translate([-frame_radius,0,-3*frame_radius])
  translate([-0.01,(clasp_length-elastic_band_clearing_w)/2,-0.01])
    cube([0.02+2*frame_radius,elastic_band_clearing_w,2*frame_radius]);

} // }}}

module connector_positive()
{ // {{{
  rotate([-90,0,0])
  {
    cylinder(r=finger_end_connection_point_radius,h=connector_depth+frame_radius,$fn=20);
  }

} // }}}

module connector_negative(extra_cutout=false,clear_for_insertion=true,hex=false)
{ // {{{
  rotate([90,0,0])
  {
    translate([0,0,0])
      cylinder(r=finger_end_connection_point_radius,h=connector_depth+frame_radius,$fn=20);
  }
  rotate([-90,0,0])
  {
    translate([0,0,-10])
      cylinder(r=m3_clear_radius,h=20,$fn=20);
    if (hex)
    {
      translate([0,0,m3_head_height])
        rotate([0,0,0.5*360/6])
          cylinder(r=m3_nut_clear_radius,h=m3_head_height+(extra_cutout?20:5),$fn=6);
    }
    else
    {
      translate([0,0,2*frame_radius-m3_head_height])
        cylinder(r=m3_head_clear_radius,h=m3_head_height+5,$fn=30);
    }
    if(clear_for_insertion)
      translate([0,0,2*frame_radius+5-0.01])
        cylinder(r=m3_head_clear_radius,h=m3_head_height+20,$fn=20);
    if(extra_cutout)
      translate([0,0,2*frame_radius+5-0.01])
        cylinder(r=m3_head_clear_radius,h=10,$fn=20);
  }
} // }}}

module connector_access_negative(hex=false)
{ // {{{
  rotate([-90,0,0])
  {
    hull ()
    {
      for (t=[0,frame_radius])
      {
        translate([0,t,m3_head_height])
          if (hex)
            rotate([0,0,0.5*360/6])
              cylinder(r=m3_nut_clear_radius,h=m3_nut_clear_height,$fn=6);
          else
            cylinder(r=m3_head_clear_radius,h=m3_nut_clear_height,$fn=20);
      }
    }
  }
} // }}}

module showcase_rotation_for_euler_rotations()
{ // {{{
 
  angles = [[119,-133,-94], [-129,112,-142], [104,-44,-139], [70,99,-85],
  [-146,171,64], [113,55,-26], [-39,-169,-58], [-8,82,39], [86,-110,-33],
  [168,119,67], [-9,58,114], [69,110,39], [99,26,175], [140,-84,95],
  [-132,-58,78], [112,-125,-47], [-94,8,-35], [20,173,-141], [-121,79,-71],
  [19,59,-131]];
              
             
  for(angle=angles)
  {           
    amplitude = 10;
    dest = amplitude*rotation_for_euler_rotations(angle)*[0,0,1];
              
    translate(dest)
      color("green")
        {      
          translate([0,0,0.2*amplitude])
            cylinder(r=0.1,h=0.8*amplitude,$fn=10);
          cylinder(r1=0.01,r2=0.4,h=0.2*amplitude,$fn=10);
        }       
                
    rotate(angle)
      color("blue")                                                       
      {                                                                  
        cylinder(r=0.1,h=0.8*amplitude,$fn=10);                         
        translate([0,0,0.8*amplitude])
          cylinder(r1=0.4,r2=0.01,h=0.2*amplitude,$fn=10);
      }                                                
  }
} // }}}

module segment (length,radius)
{ // {{{
  sphere(radius);
  cylinder(r=radius,h=length);
} // }}}

module final_segment (length,radius)
{ // {{{
  sphere(radius);
  intersection()
  {
    rotate([10,0,0])
      cylinder(r=radius,h=length);
    cylinder(r=radius,h=length);
  }

} // }}}

module compass ()
{ // {{{
  $fn=20;
  % union ()
  {
    color("red")
    {
      cylinder_from_to([0,0,0],[18,0,0],0.2,0.2);
      cylinder_from_to([18,0,0],[20,0,0],0.6,0.01);
    }
    color("green")
    {
      cylinder_from_to([0,0,0],[0,18,0],0.2,0.2);
      cylinder_from_to([0,18,0],[0,20,0],0.6,0.01);
    }
    color("blue")
    {
      cylinder_from_to([0,0,0],[0,0,18],0.2,0.2);
      cylinder_from_to([0,0,18],[0,0,20],0.6,0.01);
    }
  }
} // }}}

module contact_negative ()
{ // {{{
  contact_negative_buttonbased();
} // }}}
module contact_positive ()
{ // {{{
  contact_positive_buttonbased();
} // }}}

module contact_negative_buttonbased ()
{ // {{{
  fact = button_hole_overdimension_factor;

  // clearance for spikes
  translate([0,-6/2,-10-(2+1-contact_clearance)])
    for (yoff=[0,6-1])
      translate([0,yoff+1/2,-4])
        cylinder(r=1.5,h=10+(2+1-contact_clearance),$fn=20);

  difference()
  {
    translate([-(fact*6)/2,-(fact*6)/2,-15-(2+1-contact_clearance)])
      cube([fact*6,fact*6,15+2+(2+1-contact_clearance)+1]);


    translate([-(fact*6)/2,-(fact*6)/2,-4-(2+1-contact_clearance)-3])
      translate([0,((fact*6)-1)/2,0])
      cube([fact*6,1,3]);
  }
} // }}}

module contact_positive_buttonbased ()
{ // {{{
  translate([-6/2,-6/2,-10-(2+1-contact_clearance)])
  {
    minkowski()
    {
      cube([6,6,10+(2+1-contact_clearance)]);
      cylinder(r=2,h=0.001,$fn=20);
    }
  }

  // visualisation
  % union()
  {
    translate([-6/2,-6/2,-4-(2+1-contact_clearance)])
      color("#888888")
      cube([6,6,4]);

    // spikes
    translate([0,-6/2,-4-(2+1-contact_clearance)])
      for (yoff=[0,6-1])
        translate([-1/2,yoff,-4])
          color("#eeeeee")
          cube([1,1,4]);

    translate([-6/2,-6/2,-(2+1-contact_clearance)])
      color("#222222")
      {
        difference()
        {
          cube([6,6,2]);
          for(p=[[0.5,0.5],[0.5,5.5],[5.5,5.5],[5.5,0.5]])
            translate([p[0],p[1],-0.03])
              cylinder(r=1,h=3,$fn=10);
        }
      }

    translate([0,0,-(2+1-contact_clearance)])
      color("red")
        cylinder(r=1.5,h=3,$fn=10);
  }
} // }}}

module contact_negative_springbased ()
{ // {{{
  translate([0,0,-spring_height-m3_nut_holder_wall_w-m3_nut_clear_height])
  {
    hull()
    {
      translate([0,15,0])
        rotate([0,0,360/12])
        cylinder(r=m3_nut_clear_radius,h=m3_nut_clear_height,$fn=6);
      rotate([0,0,360/12])
        cylinder(r=m3_nut_clear_radius,h=m3_nut_clear_height,$fn=6);
    }
    translate([0,0,m3_nut_clear_height+m3_nut_holder_wall_w])
    {
      cylinder(r=spring_radius+0.4,h=2*spring_height,$fn=20);
    }
    // punch through the main m3 axis:
    translate([0,0,-m3_nut_holder_wall_w-m3_nut_clear_height])
      cylinder(r=m3_clear_radius,h=m3_bolt_visualisation_height,$fn=20);
  }
  // punch through the head spacing
  translate([0,0,-contact_z_depress-m3_nut_clear_height-0.01])
    mirror([0,0,1])
    cylinder(r=1.1*max(m3_head_clear_radius,m3_nut_clear_radius),h=10,$fn=20);

} // }}}

module contact_positive_springbased ()
{ // {{{

  // a cylinder to hold bolt and spring:
  translate([0,0,-contact_z_depress-m3_nut_clear_height])
    cylinder(r=5,h=contact_z_depress+m3_nut_clear_height,$fn=30);

  %
  // a grey spring in place:
  translate([0,0,-(spring_height-contact_clearance)])
  {
    color("silver")
    difference()
    {
      cylinder(r=spring_radius,h=spring_height,$fn=30);
      translate([0,0,-0.02])
        cylinder(r=spring_radius-0.3,h=2*spring_height,$fn=30);
    }
  }

  // Visualise locations of nuts
  %
  translate([0,0,-spring_height-m3_nut_holder_wall_w-m3_nut_clear_height])
    color("#222222")
    cylinder(r=m3_nut_clear_radius,h=m3_nut_height,$fn=6);

  %
  translate([0,0,-contact_z_depress-m3_nut_clear_height-m3_nut_height])
    color("#222222")
    cylinder(r=m3_nut_clear_radius,h=m3_nut_height,$fn=6);

  %
  // a black bolt in place:
  translate([0,0,-m3_bolt_visualisation_height])
  {
    color("#222222")
    cylinder(r=m3_radius,h=m3_bolt_visualisation_height,$fn=30);

    color("#222222")
    cylinder(r=m3_head_radius,h=m3_head_radius,$fn=30);
  }
} // }}}

// Main modules below

// A test object that can be used to establish certain calibration parameters.
module test_object ()
{ // {{{
  difference()
  {
    union ()
    {
      cube([10,30,10]);
      translate([10-5,20-5,10])
      {
        contact_positive();
      }
      translate([10-5,30-5,10])
      {
        rotate([0,0,90])
          contact_positive();
      }
      translate([0,0,5])
        rotate([0,-90,0])
        {
          rotate([0,0,180])
          contact_positive();
        }
    }
    
    translate([10-5,20-5,10])
    {
      contact_negative();
    }
    translate([10-5,30-5,10])
    {
      rotate([0,0,90])
        contact_negative();
    }
    translate([0,0,5])
      rotate([0,-90,0])
      {
        rotate([0,0,180])
        contact_negative();
      }
  }
} // }}}

// A model of the hand, as parameterised:
module hand_model ()
{ // {{{
  measurements = [
    [
      index_angles,
      index_segment_lengths,
      index_radius,
      index_joint0_offset,
      index_joint0_rotation
    ], [
      middle_angles,
      middle_segment_lengths,
      middle_radius,
      middle_joint0_offset,
      middle_joint0_rotation
    ], [
      ring_angles,
      ring_segment_lengths,
      ring_radius,
      ring_joint0_offset,
      ring_joint0_rotation
    ], [
      pinky_angles,
      pinky_segment_lengths,
      pinky_radius,
      pinky_joint0_offset,
      pinky_joint0_rotation
    ],
  ];

  for (finger_i = [0:3])
  {
    angles =          measurements[finger_i][0];
    segment_lengths = measurements[finger_i][1];
    radius =          measurements[finger_i][2];
    joint0_offset =   measurements[finger_i][3];
    joint0_rotation = measurements[finger_i][4];

    translate(joint0_offset)
    {
      rotate([0,joint0_rotation,0])
      {
        rotate([-angles[0]-90,0,0])
        {
          segment(segment_lengths[0]-2*radius,radius);
          translate([0,0,segment_lengths[0]-2*radius])
            rotate([-angles[1],0,0])
            {
              segment(segment_lengths[1]-2*radius,radius);
              translate([0,0,segment_lengths[1]-2*radius])
                rotate([-angles[2],0,0])
                {
                  final_segment(segment_lengths[2]-1*radius,radius);
                }
            }
        }
      }
    }
  }

  for (coord=thumb_coords)
    translate(coord)
      sphere(r=thumb_radius);
    
  cylinder_from_to(thumb_coords[0],thumb_coords[1],thumb_radius,thumb_radius);
  cylinder_from_to(thumb_coords[1],thumb_coords[2],thumb_radius,thumb_radius);
  /*
  translate(thumb_coords[1])
    rotate(thumb_rotation[1])
      final_segment(thumb_segment_lengths[1],thumb_radius);
  */

  cylinder_from_to(index_joint0_offset,middle_joint0_offset,index_radius,middle_radius,$fn=40);
  cylinder_from_to(middle_joint0_offset,ring_joint0_offset,middle_radius,ring_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,pinky_joint0_offset,ring_radius,pinky_radius,$fn=40);


  cylinder_from_to(thumb_joint0_offset,wristaxis_thumbside_upper_offset,thumb_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(pinky_joint0_offset,wristaxis_pinkyside_upper_offset,pinky_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,wristaxis_pinkyside_upper_offset,ring_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(index_joint0_offset,wristaxis_thumbside_upper_offset,index_radius,wristaxis_radius,$fn=40);

  cylinder_from_to(wristaxis_thumbside_upper_offset,wristaxis_pinkyside_upper_offset,wristaxis_radius,wristaxis_radius,$fn=40);

  translate(wristaxis_thumbside_upper_offset)
    sphere(r=wristaxis_radius,$fn=40);
  translate(wristaxis_pinkyside_upper_offset)
    sphere(r=wristaxis_radius,$fn=40);

} // }}}

module finger_end()
{ // {{{

  depth=15;
  // TODO/FIXME: one should be able to use thumb_coords[2] here, and be
  // over with it. That places it in a weird spot though, so...
  scale_for_thumb_contact_offset = 0.65;

  module thumb_contact_positive ()
  { // {{{
    union ()
    {
      cylinder_from_to(
        thumb_connection_point,
        thumb_connection_point+rotation_for_euler_rotations([thumb_joint0_rotation,0,0])*[0,0,scale_for_thumb_contact_offset*thumb_segment_lengths[1]],
        frame_radius,frame_radius,$fn=30);

      cylinder_from_to(
        thumb_connection_point,
        thumb_connection_point+rotation_for_euler_rotations([thumb_joint0_rotation,0,0])*[0,0,scale_for_thumb_contact_offset*thumb_segment_lengths[1]],
        frame_radius,frame_radius,$fn=30);

      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        rotate([0,90,0])
          {
            rotate([90,0,0])
            for (a=[-90,90])
            rotate([a,90,90])
              translate([0,thumb_radius+contact_clearance,0])
              rotate([-90,0,0])
              cylinder(r=5,h=contact_clearance);
            rotate([-90,-90,0])
            rotate_extrude(angle=180,$fn=60)
            {
              translate([thumb_radius+contact_clearance,-5,0])
              square([2*contact_clearance,10]);
            }
          }

      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        mirror([0,0,1])
          {
            translate([0,0,thumb_radius+contact_clearance])
              cylinder(r=frame_radius,h=thumb_connection_point_translation_distance-thumb_radius-contact_clearance,$fn=30);
          }

      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        translate([0,scale_for_thumb_contact_offset*thumb_segment_lengths[1],-depth])
        contact_positive();

    // Place the far thumb and near thumb buttons where they need to be:
      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        rotate([0,90,0])
        translate([0,0,-thumb_radius-contact_clearance])
        contact_positive();

      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        rotate([0,-90,0])
        translate([0,0,-thumb_radius-contact_clearance])
        contact_positive();
    }
  } // }}}

  module thumb_contact_negative ()
  { // {{{
    union ()
    {
      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        {
          // Negative parts of contact:
          translate([0,scale_for_thumb_contact_offset*thumb_segment_lengths[1],-depth])
          rotate([0,0,90])
            contact_negative();

          // Place the far thumb and near thumb buttons where they need to be:
          rotate([0,90,0])
            translate([0,0,-thumb_radius-contact_clearance])
            contact_negative();
          rotate([0,-90,0])
            translate([0,0,-thumb_radius-contact_clearance])
            contact_negative();
        }
    }
  } // }}}

  module contact_outrigger (joint0_offset,radius,coords,rotations)
  { // {{{
    difference()
    {
      union()
      {
          hull()
          {
            cylinder_from_to(
              joint0_offset+[0,0,-radius-frame_radius],
              coords[3]+[0,-10,0],
              frame_radius,frame_radius,$fn=40);

            cylinder_from_to(
              joint0_offset+[0,0,-radius-frame_radius],
                coords[3]+rotation_for_euler_rotations(rotations[3])*[0,0,-radius-contact_z_depress-m3_nut_clear_height-m3_nut_holder_wall_w],
              frame_radius,frame_radius,$fn=40);
          }

          translate(coords[3])
            rotate(rotations[3])
            rotate([90,0,0])
            translate([0,-6,-1*radius])
            {
              minkowski()
              {
                sphere(r=1,$fn=20);
                cylinder(r=1+radius,h=2*radius,$fn=40);
              }
            }

        translate(coords[3])
          rotate(rotations[3])
          translate([0,0,-radius-4])
          {
            rotate([0,0,90])
              contact_positive();
          }

      }

      translate(coords[3])
        rotate(rotations[3])
        translate([0,0,-radius-4])
        {
          rotate([0,0,90])
            contact_negative();
        }

      translate(coords[2])
        rotate(rotations[1])
        rotate([90,0,0])
        translate([0,-4,-10-radius])
          cylinder(r=radius,h=60);
      translate(coords[3])
        rotate(rotations[3])
        rotate([90,0,0])
        translate([0,-4,-10-radius])
          cylinder(r=radius,h=60);
      translate(coords[3])
        rotate(rotations[2])
        translate([-2*radius,-2*radius,-4])
        cube([4*radius,5*radius,3*radius]);
    }
  } // }}}

  difference()
  {
    union ()
    {
      for (connectionpoint=[
        thumb_connection_point,
        index_joint0_offset+[0,0,-index_radius-frame_radius],
        middle_joint0_offset+[0,0,-middle_radius-frame_radius],
        ring_joint0_offset+[0,0,-ring_radius-frame_radius],
        pinky_joint0_offset+[0,0,-pinky_radius-frame_radius]])
        {
          translate(connectionpoint)
          {
            sphere(r=frame_radius,$fn=30);
          }
        }

      // From index to thumb:
      cylinder_from_to(
        thumb_connection_point,
        index_joint0_offset+[0,0,-index_radius-frame_radius],
        frame_radius,frame_radius,
        $fn=30);
      // Front under-knuckles attachments:
      cylinder_from_to(
        index_joint0_offset+[0,0,-index_radius-frame_radius],
        middle_joint0_offset+[0,0,-middle_radius-frame_radius],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        middle_joint0_offset+[0,0,-middle_radius-frame_radius],
        ring_joint0_offset+[0,0,-ring_radius-frame_radius],
        frame_radius, frame_radius,$fn=30);
      cylinder_from_to(
        ring_joint0_offset+[0,0,-ring_radius-frame_radius],
        pinky_joint0_offset+[0,0,-pinky_radius-frame_radius],
        frame_radius,frame_radius,$fn=30);
 
      contact_outrigger(pinky_joint0_offset,pinky_radius,pinky_coords,pinky_rotation);
      contact_outrigger(ring_joint0_offset,ring_radius,ring_coords,ring_rotation);
      contact_outrigger(middle_joint0_offset,middle_radius,middle_coords,middle_rotation);
      contact_outrigger(index_joint0_offset,index_radius,index_coords,index_rotation);

      translate(finger_end_connection_point_thumb)
        connector_positive();
      translate(finger_end_connection_point_index)
        connector_positive();
      translate(finger_end_connection_point_pinky)
        connector_positive();

      thumb_contact_positive();
    }
    union()
    {
      translate(finger_end_connection_point_thumb)
        connector_negative(clear_for_insertion=false);
      translate(finger_end_connection_point_index)
        connector_negative();
      translate(finger_end_connection_point_pinky)
        connector_negative();
      thumb_contact_negative();
    }
  }

} // }}}


module body()
{ // {{{
  body_front_thumb_offset = finger_end_connection_point_thumb+[0,-2*connector_depth,0];
  body_front_index_offset = index_joint0_offset + [0,-10-connector_depth,-index_radius-frame_radius];
  body_front_pinky_offset = pinky_joint0_offset + [-5,-10-connector_depth,-pinky_radius-frame_radius];

  body_finger_end_connection_point_thumb = finger_end_connection_point_thumb + [0,-2*connector_depth-frame_radius,0];
  body_finger_end_connection_point_index = finger_end_connection_point_index + [0,-2*connector_depth-frame_radius,0];
  body_finger_end_connection_point_pinky = finger_end_connection_point_pinky + [0,-2*connector_depth-frame_radius,0];

  rotational_offset_pinkyside_clasp = 40;
  rotation_of_pinkyside_clasp = rotation_of_vector(
    body_wristaxis_pinkyside_upper_offset
    -body_front_pinky_offset) + [0,0,0];

  location_of_pinkyside_clasp=
    body_wristaxis_pinkyside_upper_offset
    -rotation_for_euler_rotations(rotation_of_pinkyside_clasp)
    *[0,0,frame_radius];

  rotational_offset_thumbside_clip = -20;
  rotation_of_thumbside_clip = rotation_of_vector(
    body_wristaxis_thumbside_lower_offset
    -body_front_thumb_offset);

  location_of_thumbside_clip=
    body_wristaxis_thumbside_lower_offset
    +rotation_for_euler_rotations(rotation_of_thumbside_clip)
    *[0,0,-2*frame_radius];

  // A fairly arbitrary point in the middle of the body shape:
  _base_mcu_corner = [
    0.4*index_joint0_offset[0]+0.6*ring_joint0_offset[0],
    0.5*thumb_coords[1][1]+0.5*wristaxis_thumbside_upper_offset[1],
    -70];

  body_mcu_box_corners = [
    _base_mcu_corner + [0.5*mcu_clearance_wdh[0], 0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [0.5*mcu_clearance_wdh[0], -0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [-0.5*mcu_clearance_wdh[0],-0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [-0.5*mcu_clearance_wdh[0],0.5*mcu_clearance_wdh[1],0],
  ];

  
  _lipo_base = body_wristaxis_thumbside_lower_offset+[frame_radius,0,0];
  lipo_compartment_corners = [
     _lipo_base+[0,0,lipo_compartment_wdh[0]],
     _lipo_base,
     _lipo_base+[lipo_compartment_wdh[1],0,0],
     _lipo_base+[lipo_compartment_wdh[1],0,lipo_compartment_wdh[0]],
     /* _lipo_base, */
     /* _lipo_base+[0,0,-lipo_compartment_wdh[0]], */
     /* _lipo_base+[lipo_compartment_wdh[1],0,-lipo_compartment_wdh[0]], */
     /* _lipo_base+[lipo_compartment_wdh[1],0,0], */
  ];

  difference()
  {
    union()
    {
      for (offs=[
        body_front_index_offset,
        body_front_pinky_offset,
        body_front_thumb_offset,
        body_finger_end_connection_point_index,
        body_finger_end_connection_point_pinky,
        body_wristaxis_thumbside_upper_offset,
        body_wristaxis_pinkyside_upper_offset,
        body_wristaxis_pinkyside_lower_offset,
        body_wristaxis_thumbside_lower_offset,
        body_mcu_box_corners[0],
        body_mcu_box_corners[1],
        body_mcu_box_corners[2],
        body_mcu_box_corners[3],
        lipo_compartment_corners[0],
        lipo_compartment_corners[1],
        lipo_compartment_corners[2],
        lipo_compartment_corners[3],
        ])
      {
        translate(offs)
        {
          sphere(r=frame_radius,$fn=20);
        }
      }

      translate(finger_end_connection_point_thumb)
        mirror([0,1,0])
        connector_positive();
      translate(finger_end_connection_point_index)
        mirror([0,1,0])
          connector_positive();
      translate(finger_end_connection_point_pinky)
        mirror([0,1,0])
          connector_positive();

      for (point=[
        wrist_handle_connection_point_thumb_upper,
        wrist_handle_connection_point_thumb_lower,
        wrist_handle_connection_point_pinky_upper,
        wrist_handle_connection_point_pinky_lower,
        ])
        translate(point)
          connector_positive();

      // Connectors in the front:
      cylinder_from_to(
        body_front_index_offset,
        //0.9*body_front_index_offset+0.1*body_wristaxis_thumbside_upper_offset,
        body_front_thumb_offset,
        frame_radius,frame_radius,
        $fn=30);



      cylinder_from_to(
        body_front_index_offset,
        body_finger_end_connection_point_index,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        body_finger_end_connection_point_index,
        body_finger_end_connection_point_pinky,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        body_finger_end_connection_point_pinky,
        body_front_pinky_offset,
        frame_radius,frame_radius,
        $fn=30);

      // Connectors front to back:

      // this one will be taking the pinky side clasp:
      cylinder_from_to(
        body_front_pinky_offset,
        body_wristaxis_pinkyside_upper_offset,
        frame_radius,frame_radius,
        $fn=30);
      

      translate(location_of_pinkyside_clasp)
        rotate(rotation_of_pinkyside_clasp+[0,-90,0])
          rotate([0,-90+rotational_offset_pinkyside_clasp,90])
          translate([-frame_radius,0,-frame_radius])
            elastic_clasp_positive();

      translate(location_of_thumbside_clip)
        rotate(rotation_of_thumbside_clip+[0,-90,0])
          rotate([0,rotational_offset_thumbside_clip,90])
            elastic_clip_positive();

      // Connectors in the back
      cylinder_from_to(
        body_wristaxis_thumbside_upper_offset,
        body_wristaxis_pinkyside_upper_offset,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_upper_offset,
        body_wristaxis_thumbside_lower_offset,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_pinkyside_upper_offset,
        body_wristaxis_pinkyside_lower_offset,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_lower_offset,
        body_wristaxis_pinkyside_lower_offset,
        frame_radius,frame_radius,
        $fn=30);

      // Connectors to the MCU
      cylinder_from_to(
        body_front_thumb_offset,
        body_mcu_box_corners[3],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_front_pinky_offset,
        body_mcu_box_corners[0],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_upper_offset,
        body_mcu_box_corners[2],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_lower_offset,
        body_mcu_box_corners[2],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_pinkyside_lower_offset,
        body_mcu_box_corners[1],
        frame_radius,frame_radius,
        $fn=30);

      // Connectors to the LiPo compartment
      cylinder_from_to(
        body_wristaxis_thumbside_upper_offset,
        lipo_compartment_corners[0],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_lower_offset,
        lipo_compartment_corners[1],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_pinkyside_lower_offset,
        lipo_compartment_corners[2],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_pinkyside_upper_offset,
        lipo_compartment_corners[3],
        frame_radius,frame_radius,
        $fn=30);
      hull()
      {
        for (i=[0:3])
        {
          translate(lipo_compartment_corners[i]+[0,lipo_compartment_wdh[2],0])
            sphere(r=frame_radius,$fn=30);
          cylinder_from_to(
            lipo_compartment_corners[i]+[0,lipo_compartment_wdh[2],0],
            lipo_compartment_corners[(i+1)%4]+[0,lipo_compartment_wdh[2],0],
            frame_radius,frame_radius,
            $fn=30);
          cylinder_from_to(
            lipo_compartment_corners[i],
            lipo_compartment_corners[(i+1)%4],
            frame_radius,frame_radius,
            $fn=30);
        }
      }

      // This will have an elastic clip attached to it:
      cylinder_from_to(
        body_front_thumb_offset,
        body_wristaxis_thumbside_lower_offset,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_front_index_offset,
        body_mcu_box_corners[3],
        frame_radius,frame_radius,
        $fn=30);

      // Connectors around the MCU
      for(i=[0:3])
        cylinder_from_to(
          body_mcu_box_corners[i],
          body_mcu_box_corners[(i+1)%4],
          frame_radius,frame_radius,
          $fn=30);

      // Illustrate where the MCU sits:
      %
      translate(body_mcu_box_corners[2])
        color([0,0,1,0.2])
        mcu_clearance_box();
    }
    union()
    {
      translate(finger_end_connection_point_thumb)
        mirror([0,1,0])
          connector_negative(extra_cutout=true,hex=true,clear_for_insertion=false);
      translate(finger_end_connection_point_index)
        mirror([0,1,0])
          connector_negative(extra_cutout=true,hex=true);
      translate(finger_end_connection_point_pinky)
        mirror([0,1,0])
          connector_negative(extra_cutout=true,hex=true);

      translate(location_of_pinkyside_clasp)
        rotate(rotation_of_pinkyside_clasp+[0,-90,0])
          rotate([0,-90+rotational_offset_pinkyside_clasp,90])
          translate([-frame_radius,0,-frame_radius])
            elastic_clasp_negative();

      translate(location_of_thumbside_clip)
        rotate(rotation_of_thumbside_clip+[0,-90,0])
          rotate([0,rotational_offset_thumbside_clip,90])
            elastic_clip_negative();

      // Cavity for lipo_compartment_wdh:
      translate(lipo_compartment_corners[1])
        cube([
          lipo_compartment_wdh[1],
          lipo_compartment_wdh[2],
          2*lipo_compartment_wdh[0]]);

      // Place LiPo cable exit slit
      translate(
        lipo_compartment_corners[2]+[
          -5,
          lipo_compartment_wdh[2]-0.01,
          0])
        cube([
          5,
          lipo_compartment_wdh[2],
          lipo_compartment_wdh[0]-5]);

      for (point=[
        wrist_handle_connection_point_thumb_upper,
        wrist_handle_connection_point_thumb_lower,
        wrist_handle_connection_point_pinky_upper,
        wrist_handle_connection_point_pinky_lower,
        ])
        translate(point)
          connector_negative(extra_cutout=false);

      translate(body_mcu_box_corners[2])
        mcu_clearance_box();
      
    }
  }

} // }}}

module wrist_handle()
{ // {{{
  wrist_handle_wristaxis_front_upper_thumbside = body_wristaxis_thumbside_upper_offset + [0,-4*connector_depth,0];
  wrist_handle_wristaxis_front_upper_pinkyside = body_wristaxis_pinkyside_upper_offset + [0,-4*connector_depth,0];
  wrist_handle_wristaxis_front_lower_thumbside = body_wristaxis_thumbside_lower_offset + [0,-2*connector_depth-frame_radius,0];
  wrist_handle_wristaxis_front_lower_pinkyside = body_wristaxis_pinkyside_lower_offset + [0,-2*connector_depth-frame_radius,0];

  wrist_handle_point_rear_thumbside = body_wristaxis_thumbside_upper_offset + [0,-80,0];
  wrist_handle_point_rear_pinkyside = body_wristaxis_pinkyside_upper_offset + [0,-80,0];

  wrist_handle_elastic_coords = [
    0.25*body_wristaxis_pinkyside_upper_offset+
    0.75*wrist_handle_point_rear_pinkyside,
  ];
  difference()
  {
    union()
    {
      for (offs=[
          wrist_handle_point_rear_thumbside,
          wrist_handle_point_rear_pinkyside,
        ])
      {
        translate(offs)
        {
          sphere(r=frame_radius,$fn=20);
        }
      }

      for (point=[
        wrist_handle_connection_point_thumb_upper,
        wrist_handle_connection_point_thumb_lower,
        wrist_handle_connection_point_pinky_upper,
        wrist_handle_connection_point_pinky_lower,
        ])
        translate(point)
          mirror([0,1,0])
            connector_positive();

      for (coord=wrist_handle_elastic_coords)
      {
        translate(coord)
        {
          translate([-5,0,-frame_radius])
            elastic_clasp_positive();
        }
      }

      translate(0.25*body_wristaxis_thumbside_upper_offset+
          0.75*wrist_handle_point_rear_thumbside)
      {
        elastic_clip_positive();
      }


      cylinder_from_to(
        wrist_handle_point_rear_pinkyside,
        wrist_handle_point_rear_thumbside,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        wrist_handle_wristaxis_front_upper_thumbside,
        wrist_handle_point_rear_thumbside,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        wrist_handle_wristaxis_front_lower_thumbside,
        wrist_handle_point_rear_pinkyside,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        wrist_handle_wristaxis_front_upper_pinkyside,
        wrist_handle_point_rear_pinkyside,
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        wrist_handle_wristaxis_front_lower_pinkyside,
        wrist_handle_point_rear_thumbside,
        frame_radius,frame_radius,
        $fn=30);

    }
    union()
    {
      for (point=[
        wrist_handle_connection_point_pinky_upper,
        wrist_handle_connection_point_thumb_upper,
        ])
        translate(point)
          mirror([0,1,0])
          {
            connector_negative(extra_cutout=false,clear_for_insertion=false,hex=true);
            connector_access_negative(hex=true);
          }
      for (point=[
        wrist_handle_connection_point_thumb_lower,
        wrist_handle_connection_point_pinky_lower,
        ])
        translate(point)
          mirror([0,1,0])
            connector_negative(extra_cutout=true,hex=true);


      for (coord=wrist_handle_elastic_coords)
      {
        translate(coord)
        {
          translate([-5,0,-frame_radius])
            elastic_clasp_negative();
        }
      }

      translate(0.25*body_wristaxis_thumbside_upper_offset+
          0.75*wrist_handle_point_rear_thumbside)
      {
        elastic_clip_negative();
      }
    }
  }

} // }}}

finger_end();

body();
wrist_handle();

translate([-60,-100,-40])
  test_object();

% hand_model();
// vim: fml=1 fdm=marker
