within TRANSFORM.Fluid.Pipes.Examples.TransportDelayPipeTests;
model Test1_MultiSpeciesMultiTrace

  extends Icons.Example;

  //package Medium=Modelica.Media.Air.MoistAir(extraPropertiesNames={"A"});
  //package Medium=Modelica.Media.Water.StandardWater(extraPropertiesNames={"A","B"});
  package Medium =
      Modelica.Media.IdealGases.MixtureGases.SimpleNaturalGas (          extraPropertiesNames={"A","B"});

  TransportDelayPipe transportDelayPipe(
    redeclare package Medium = Medium,
    length=10,
    crossArea=0.01)
    annotation (Placement(transformation(extent={{-8,-10},{12,10}})));
  BoundaryConditions.Boundary_pT boundary(
    nPorts=1,
    p=200000,
    T=293.15,
    redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{70,-10},{50,10}})));
  BoundaryConditions.MassFlowSource_T boundary1(
    nPorts=1,
    m_flow=1,
    use_m_flow_in=true,
    redeclare package Medium = Medium,
    use_X_in=false,
    use_C_in=false,
    use_T_in=false,
    C={0.001,0.005},
    T=323.15,
    X={0.05,0.06,0.07,0.08,0.09,0.65})
    annotation (Placement(transformation(extent={{-38,-10},{-18,10}})));
  Modelica.Blocks.Sources.Step step2(
    startTime=1,
    height=1,
    offset=0)
    annotation (Placement(transformation(extent={{-100,20},{-80,40}})));
  Modelica.Blocks.Math.Add add1
    annotation (Placement(transformation(extent={{-72,-2},{-52,18}})));
  Modelica.Blocks.Sources.Step step3(
    height=-2,
    offset=0,
    startTime=5)
    annotation (Placement(transformation(extent={{-100,-8},{-80,12}})));
  Utilities.ErrorAnalysis.UnitTests           unitTests(n=3, x={
        transportDelayPipe.port_a.h_outflow,transportDelayPipe.port_b.h_outflow,
        transportDelayPipe.port_a.m_flow})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(boundary1.ports[1], transportDelayPipe.port_a)
    annotation (Line(points={{-18,0},{-18,0},{-8,0}},  color={0,127,255}));
  connect(transportDelayPipe.port_b, boundary.ports[1]) annotation (Line(
      points={{12,0},{12,0},{50,0}},
      color={0,127,255},
      thickness=0.5));
  connect(step3.y, add1.u2) annotation (Line(points={{-79,2},{-79,2},{-78,2},{
          -74,2}},    color={0,0,127}));
  connect(step2.y, add1.u1) annotation (Line(points={{-79,30},{-78,30},{-78,14},
          {-74,14}},            color={0,0,127}));
  connect(add1.y, boundary1.m_flow_in) annotation (Line(points={{-51,8},{-50,8},
          {-38,8}},                  color={0,0,127}));

  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    experiment(StopTime=10));
end Test1_MultiSpeciesMultiTrace;
