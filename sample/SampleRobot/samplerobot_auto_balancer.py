#!/usr/bin/env python

try:
    from hrpsys.hrpsys_config import *
    import OpenHRP
except:
    print "import without hrpsys"
    import rtm
    from rtm import *
    from OpenHRP import *
    import waitInput
    from waitInput import *
    import socket
    import time

def init ():
    global hcf
    hcf = HrpsysConfigurator()
    hcf.getRTCList = hcf.getRTCListUnstable
    hcf.init ("SampleRobot(Robot)0", "$(PROJECT_DIR)/../model/sample1.wrl")

def testPoseList(pose_list, initial_pose):
    for pose in pose_list:
        hcf.seq_svc.setJointAngles(pose, 1.0)
        hcf.seq_svc.waitInterpolation()
        hcf.seq_svc.setJointAngles(initial_pose, 1.0)
        hcf.seq_svc.waitInterpolation()

def demo():
    init()
    # set initial pose from sample/controller/SampleController/etc/Sample.pos
    initial_pose = [-7.779e-005,  -0.378613,  -0.000209793,  0.832038,  -0.452564,  0.000244781,  0.31129,  -0.159481,  -0.115399,  -0.636277,  0,  0,  0.637045,  -7.77902e-005,  -0.378613,  -0.000209794,  0.832038,  -0.452564,  0.000244781,  0.31129,  0.159481,  0.115399,  -0.636277,  0,  0,  -0.637045,  0,  0,  0]
    arm_front_pose = [-7.778932e-05,-0.378613,-0.00021,0.832039,-0.452564,0.000245,-1.5708,-0.159481,-0.115399,-0.349066,0.0,0.0,0.0,-7.778932e-05,-0.378613,-0.00021,0.832039,-0.452564,0.000245,-1.5708,0.159481,0.115399,-0.349066,0.0,0.0,0.0,0.0,0.0,0.0]
    half_sitting_pose = [-0.000158,-0.570987,-0.000232,1.26437,-0.692521,0.000277,0.31129,-0.159481,-0.115399,-0.636277,0.0,0.0,0.0,-0.000158,-0.570987,-0.000232,1.26437,-0.692521,0.000277,0.31129,0.159481,0.115399,-0.636277,0.0,0.0,0.0,0.0,0.0,0.0]
    root_rot_x_pose = [-0.241557,-0.634167,0.011778,1.30139,-0.668753,0.074236,0.31129,-0.159481,-0.115399,-0.636277,0.0,0.0,0.0,-0.233491,-0.555191,0.011181,1.13468,-0.580942,0.065086,0.31129,0.159481,0.115399,-0.636277,0.0,0.0,0.0,0.0,0.0,0.0]
    root_rot_y_pose = [8.251963e-05,-0.980029,-0.000384,1.02994,-0.398115,-0.000111,0.31129,-0.159481,-0.115399,-0.636277,0.0,0.0,0.0,8.252625e-05,-0.980033,-0.000384,1.02986,-0.398027,-0.000111,0.31129,0.159481,0.115399,-0.636277,0.0,0.0,0.0,0.0,0.0,0.0]
    pose_list=[half_sitting_pose, root_rot_x_pose, root_rot_y_pose, arm_front_pose]
    hcf.seq_svc.setJointAngles(initial_pose, 2.0)
    hcf.seq_svc.waitInterpolation()

    # sample for AutoBalancer mode
    #   1. AutoBalancer mode by fixing feet
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    hcf.seq_svc.setJointAngles(arm_front_pose, 1.0)
    hcf.seq_svc.waitInterpolation()
    hcf.seq_svc.setJointAngles(initial_pose, 1.0)
    hcf.seq_svc.waitInterpolation()
    hcf.abc_svc.stopAutoBalancer();
    print "Start and Stop AutoBalancer by fixing feet=>OK"
    #   2. AutoBalancer mode by fixing hands and feet
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg", "rarm", "larm"])
    hcf.seq_svc.setJointAngles(arm_front_pose, 1.0)
    hcf.seq_svc.waitInterpolation()
    hcf.seq_svc.setJointAngles(initial_pose, 1.0)
    hcf.seq_svc.waitInterpolation()
    hcf.abc_svc.stopAutoBalancer();
    print "Start and Stop AutoBalancer by fixing hands and feet=>OK"
    #   3. getAutoBalancerParam
    ret = hcf.abc_svc.getAutoBalancerParam()
    if ret[0]:
        print "getAutoBalancerParam() => OK"
    #   4. setAutoBalancerParam
    ret[1].default_zmp_offsets = [[0.1,0,0], [0.1,0,0]]
    hcf.abc_svc.setAutoBalancerParam(ret[1])
    if ret[0] and ret[1].default_zmp_offsets == [[0.1,0,0], [0.1,0,0]]:
        print "setAutoBalancerParam() => OK"
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    hcf.abc_svc.stopAutoBalancer();
    ret[1].default_zmp_offsets = [[0,0,0], [0,0,0]]
    hcf.abc_svc.setAutoBalancerParam(ret[1])
    #   5. change base height, base rot x, base rot y, and upper body while AutoBalancer mode
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    testPoseList(pose_list, initial_pose)
    hcf.abc_svc.stopAutoBalancer();
    #   6. start stop check
    ret[1].default_zmp_offsets = [[-0.05,0.05,0], [-0.05,0.05,0]]
    hcf.abc_svc.setAutoBalancerParam(ret[1])
    hcf.log_svc.maxLength(1500)
    for pose in pose_list:
        hcf.seq_svc.setJointAngles(pose, 1.0)
        hcf.seq_svc.waitInterpolation()
        hcf.log_svc.clear()
        hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
        hcf.abc_svc.stopAutoBalancer();
        hcf.log_svc.save("/tmp/test-samplerobot-abc-startstop-{0}".format(pose_list.index(pose)))
    ret[1].default_zmp_offsets = [[0,0,0], [0,0,0]]
    hcf.abc_svc.setAutoBalancerParam(ret[1])
    hcf.seq_svc.setJointAngles(initial_pose, 1.0)
    hcf.seq_svc.waitInterpolation()
    #   7. balance against hand force
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    hcf.seq_svc.setWrenches([0,0,0,0,0,0,
                             0,0,0,0,0,0,
                             0,0,0,0,0,0,
                             0,0,-50,0,0,0,], 1.0); # rhsensor
    hcf.seq_svc.waitInterpolation();
    hcf.seq_svc.setWrenches([0,0,0,0,0,0,
                             0,0,0,0,0,0,
                             0,0,0,0,0,0,
                             0,0,0,0,0,0,], 1.0);
    hcf.seq_svc.waitInterpolation();
    hcf.abc_svc.stopAutoBalancer();

    # sample for walk pattern generation by AutoBalancer RTC
    #   1. goPos
    hcf.abc_svc.goPos(0.1, 0.05, 20)
    hcf.abc_svc.waitFootSteps()
    print "goPos()=>OK"
    #   2. goVelocity and goStop
    hcf.abc_svc.goVelocity(-0.1, -0.05, -20)
    time.sleep(1)
    hcf.abc_svc.goStop()
    print "goVelocity()=>OK"
    #   3. setFootSteps
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0,0.09,0], [1,0,0,0], "lleg")])
    hcf.abc_svc.waitFootSteps()
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0.15,0.09,0], [1,0,0,0], "lleg"), OpenHRP.AutoBalancerService.Footstep([0.3,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0.3,0.09,0], [1,0,0,0], "lleg")])
    hcf.abc_svc.waitFootSteps()
    print "setFootSteps()=>OK"
    #   4. change base height, base rot x, base rot y, and upper body while walking
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    hcf.abc_svc.waitFootSteps()
    hcf.abc_svc.goVelocity(0,0,0)
    testPoseList(pose_list, initial_pose)
    hcf.abc_svc.goStop()
    hcf.abc_svc.stopAutoBalancer();
    #   5. getGaitGeneratorParam
    ret1 = hcf.abc_svc.getGaitGeneratorParam()
    if ret1[0]:
        print "getGaitGeneratorParam() => OK"
    #   6. setGaitGeneratorParam
    newparam = hcf.abc_svc.getGaitGeneratorParam()
    newparam[1].default_step_time = 0.7
    newparam[1].default_step_height = 0.15
    newparam[1].default_double_support_ratio = 0.4
    newparam[1].default_orbit_type = OpenHRP.AutoBalancerService.RECTANGLE;
    hcf.abc_svc.setGaitGeneratorParam(newparam[1])
    ret2 = hcf.abc_svc.getGaitGeneratorParam()
    if ret2[0] and ret2[1].default_step_time == newparam[1].default_step_time and ret2[1].default_step_height == newparam[1].default_step_height and ret2[1].default_double_support_ratio == newparam[1].default_double_support_ratio and ret2[1].default_orbit_type == newparam[1].default_orbit_type:
        print "setGaitGeneratorParam() => OK"
    hcf.abc_svc.goVelocity(0.1,0,0)
    time.sleep(1)
    hcf.abc_svc.goStop()
    hcf.abc_svc.setGaitGeneratorParam(ret1[1]) # revert parameter
    #   7. non-default stride
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0.15,0.09,0], [1,0,0,0], "lleg")])
    hcf.abc_svc.waitFootSteps()
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0,0.09,0], [1,0,0,0], "lleg")])
    hcf.abc_svc.waitFootSteps()
    hcf.abc_svc.stopAutoBalancer();
    print "Non default Stride()=>OK"
    #   8. Use toe heel contact
    hcf.abc_svc.startAutoBalancer(["rleg", "lleg"]);
    ggp=hcf.abc_svc.getGaitGeneratorParam()[1];
    ggp.toe_pos_offset_x = 1e-3*182.0;
    ggp.heel_pos_offset_x = 1e-3*-72.0;
    ggp.toe_zmp_offset_x = 1e-3*182.0;
    ggp.heel_zmp_offset_x = 1e-3*-72.0;
    ggp.toe_angle = 20;
    ggp.heel_angle = 10;
    hcf.abc_svc.setGaitGeneratorParam(ggp);
    hcf.abc_svc.goPos(0.3, 0, 0);
    hcf.abc_svc.waitFootSteps()
    hcf.abc_svc.stopAutoBalancer();
    ggp.toe_angle = 0;
    ggp.heel_angle = 0;
    hcf.abc_svc.setGaitGeneratorParam(ggp);
    print "Toe heel contact=>OK"
    #  9. Stop and start auto balancer sync check
    #   Check 9-1 Sync after setFootSteps
    hcf.startAutoBalancer();
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0.1,0.09,0], [1,0,0,0], "lleg")]);
    hcf.abc_svc.waitFootSteps();
    hcf.stopAutoBalancer();
    print "Sync after setFootSteps => OK"
    #   Check 9-2 Sync from setJointAngles at the beginning
    open_stride_pose = [0.00026722677758058496, -0.3170503560247552, -0.0002054613599000865, 0.8240549352035262, -0.5061434785447525, -8.67443660992421e-05, 0.3112899999999996, -0.15948099999999998, -0.11539900000000003, -0.6362769999999993, 0.0, 0.0, 0.0, 0.00023087433689200683, -0.4751295978345554, -0.00021953834197007937, 0.8048588066686679, -0.3288687069275527, -8.676469399681631e-05, 0.3112899999999996, 0.15948099999999998, 0.11539900000000003, -0.6362769999999993, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    hcf.seq_svc.setJointAngles(open_stride_pose, 2.0);
    hcf.seq_svc.waitInterpolation();
    hcf.startAutoBalancer();
    hcf.abc_svc.setFootSteps([OpenHRP.AutoBalancerService.Footstep([0,-0.09,0], [1,0,0,0], "rleg"), OpenHRP.AutoBalancerService.Footstep([0.1,0.09,0], [1,0,0,0], "lleg")]);
    hcf.abc_svc.waitFootSteps();
    hcf.stopAutoBalancer();
    print "Sync from setJointAngle at the beginning => OK"
    #   Check 9-3 Sync from setJointAngles
    hcf.startAutoBalancer();
    hcf.seq_svc.setJointAngles(initial_pose, 2.0);
    hcf.seq_svc.waitInterpolation();
    hcf.stopAutoBalancer();
    print "Sync from setJointAngle => OK"
    #  7. walking by fixing 
    # abc_svc.startAutoBalancer([AutoBalancerService.AutoBalancerLimbParam("rleg", [0,0,0], [0,0,0,0]),
    #                   AutoBalancerService.AutoBalancerLimbParam("lleg", [0,0,0], [0,0,0,0]),
    #                   AutoBalancerService.AutoBalancerLimbParam("rarm", [0,0,0], [0,0,0,0]),
    #                   AutoBalancerService.AutoBalancerLimbParam("larm", [0,0,0], [0,0,0,0])])
    # abc_svc.goPos(0.1, 0.05, 20)
    # abc_svc.waitFootSteps()
    # abc_svc.stopABC()

if __name__ == '__main__':
    demo()

