

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
// TODO: how does one measure these?
pinky_segment_lengths  = [ 53,  32, 28 ];
ring_segment_lengths   = [ 65,  40, 33 ];
middle_segment_lengths = [ 69,  44, 31 ];
index_segment_lengths  = [ 65,  39, 31 ];
thumb_segment_lengths  = [ 54,  51 ];

// Radii of each finger:
pinky_radius  =  7.5;
ring_radius   =  9.0;
middle_radius = 10.0;
index_radius  = 10.0;
thumb_radius  = 13.0;

// Angles at joint 0, joint 1 and joint 2, for a "comfortably glove-shaped" hand:
pinky_angles  = [20,40,20];
ring_angles   = [20,60,15];
middle_angles = [15,60,10];
index_angles  = [20,30,10];
thumb_angles  = [0,30];

// Almost-guesstimate: for a fingers-stretched hand, where are the joint 0's?
//
pinky_joint0_offset  = [ 128, -25,-20];
ring_joint0_offset   = [  96, -10,-10];
middle_joint0_offset = [  64,   0,  0];
index_joint0_offset  = [  32,  -2,  0];
thumb_joint0_offset  = [   0, -40,-50];

wristaxis_thumbside_offset  = [  32, -120,-25];
wristaxis_pinkyside_offset  = [ 112, -120,-25];
wristaxis_radius = 20;

pinky_joint0_rotation  =  12;
ring_joint0_rotation   =   0;
middle_joint0_rotation =  -3;
index_joint0_rotation  = -10;
thumb_joint0_rotation  = -90;


module cylinder_from_to (origin,dest,radius1,radius2)
{
  length = sqrt(
    pow(origin[0]-dest[0],2)+
    pow(origin[1]-dest[1],2)+
    pow(origin[2]-dest[2],2)
  );

  rotation_upwards = atan((dest[2]-origin[2])/sqrt(pow(dest[0]-origin[0],2)+pow(dest[1]-origin[1],2)));

  tangent = (dest[1]-origin[1])/(dest[0]-origin[0]);
  rotation_in_plane = atan(tangent) + (0 > (dest[0]-origin[0]) ? 180 : 0);
  //echo("rot_plane=",rotation_in_plane,"rot_upwards=",rotation_upwards,"len=",length,"tan=",tangent);
  translate(origin)
    rotate([0,0,rotation_in_plane])
    rotate([0,-rotation_upwards,0])
    rotate([0,90,0])
      cylinder(r1=radius1,r2=radius2,h=length);
}

module segment (length,radius)
{
  sphere(radius);
  cylinder(r=radius,h=length);
}

module final_segment (length,radius)
{
  sphere(radius);
  intersection()
  {
    rotate([10,0,0])
      cylinder(r=radius,h=length);
    cylinder(r=radius,h=length);
  }

}

module hand_model ()
{
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

  // TODO: these should compensate for the size of the ball of each joint,
  // given this is how the segment_lengths are measured.
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

  translate(thumb_joint0_offset)
  {
    rotate([0,thumb_joint0_rotation,0])
    {
      rotate([-thumb_joint0_offset[0]-90,0,0])
      {
        segment(thumb_segment_lengths[0]-2*thumb_radius,thumb_radius);
        translate([0,0,thumb_segment_lengths[0]-2*thumb_radius])
          rotate([-thumb_angles[1],0,0])
            final_segment(thumb_segment_lengths[1]-thumb_radius,thumb_radius);
      }
    }
  }

  cylinder_from_to(thumb_joint0_offset,index_joint0_offset,thumb_radius,index_radius,$fn=40);
  cylinder_from_to(index_joint0_offset,middle_joint0_offset,index_radius,middle_radius,$fn=40);
  cylinder_from_to(middle_joint0_offset,ring_joint0_offset,middle_radius,ring_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,pinky_joint0_offset,ring_radius,pinky_radius,$fn=40);

  cylinder_from_to(thumb_joint0_offset,wristaxis_thumbside_offset,thumb_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(pinky_joint0_offset,wristaxis_pinkyside_offset,pinky_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,wristaxis_pinkyside_offset,ring_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(index_joint0_offset,wristaxis_thumbside_offset,index_radius,wristaxis_radius,$fn=40);

  cylinder_from_to(wristaxis_thumbside_offset,wristaxis_pinkyside_offset,wristaxis_radius,wristaxis_radius,$fn=40);

  translate(wristaxis_thumbside_offset)
    sphere(r=wristaxis_radius,$fn=40);
  translate(wristaxis_pinkyside_offset)
    sphere(r=wristaxis_radius,$fn=40);

}

hand_model();
