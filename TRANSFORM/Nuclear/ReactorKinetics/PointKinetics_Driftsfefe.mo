within TRANSFORM.Nuclear.ReactorKinetics;
model PointKinetics_Driftsfefe
  import TRANSFORM;

  import TRANSFORM.Types.Dynamics;
  import TRANSFORM.Math.fillArray_1D;

  parameter Integer nV=1 "# of discrete volumes";
  parameter Integer nI=6 "# of delayed-neutron precursors groups";
  parameter SI.Power Q_nominal=1e6 "Total nominal reactor power";
  parameter Boolean specifyPower=false
    "=true to specify power (i.e., no der(P) equation)";

  // Inputs

  input SI.Mass[nV,nI] mCs
    "Absolute delayed precursor group concentration per volume"
    annotation (Dialog(group="Inputs"));
  input SI.Power[nV] Qs_input=fill(Q_nominal/nV, nV)
    "Specifed power if specifyPower=true"
    annotation (Dialog(group="Inputs", enable=specifyPower));
  input Units.InverseTime Ns_external[nV]=zeros(nV)
    "Rate of neutrons added from an external neutron source"
    annotation (Dialog(group="Inputs"));
  input Units.NonDim[nV] rhos_input=zeros(nV) "External Reactivity"
    annotation (Dialog(group="Inputs"));

  // Neutron Kinetics
  input TRANSFORM.Units.InverseTime[nI] lambda_i={0.0125,0.0318,0.109,0.317,1.35,
      8.64} "Decay constants for each precursor group" annotation (Dialog(tab="Kinetics",
        group="Inputs Neutron Kinetics"));
  input TRANSFORM.Units.NonDim[nI] alpha_i={0.0320,0.1664,0.1613,0.4596,0.1335,0.0472}
    "Normalized precursor fractions" annotation (Dialog(tab="Kinetics", group="Inputs Neutron Kinetics"));
  input TRANSFORM.Units.NonDim[nI] beta_i=alpha_i*Beta
    "Delayed neutron precursor fractions" annotation (Dialog(tab="Kinetics",
        group="Inputs Neutron Kinetics"));
  input TRANSFORM.Units.NonDim Beta=0.0065
    "Effective delay neutron fraction [e.g., Beta = sum(beta_i)]" annotation (
      Dialog(tab="Kinetics", group="Inputs Neutron Kinetics"));
  input Units.NonDim nu_bar=2.4 "Neutrons per fission" annotation (Dialog(tab="Kinetics",
        group="Inputs Neutron Kinetics"));
  input SI.Energy w_f=200e6*1.6022e-19 "Energy released per fission"
    annotation (Dialog(tab="Kinetics", group="Inputs Neutron Kinetics"));
  input SI.Time Lambda=1e-5 "Prompt neutron generation time" annotation (Dialog(
        tab="Kinetics", group="Inputs Neutron Kinetics"));

  // Reactivity Feedback
  parameter Integer nFeedback = 1 "# of reactivity feedbacks (alpha*(val-val_ref)" annotation (Dialog(tab="Kinetics",
        group="Inputs Reactivity Feedback"));
  input Real alphas_feedback[nV,nFeedback]=fill(
      -1e-4,
      nV,
      nFeedback) "Reactivity feedback coefficient (e.g., temperature [1/K])"
                                       annotation (Dialog(tab="Kinetics", group="Inputs Reactivity Feedback"));
  input Real vals_feedback[nV,nFeedback] = vals_feedback_reference "Variable value for reactivity feedback (e.g. fuel temperature)"
    annotation (Dialog(tab="Kinetics",group="Inputs Reactivity Feedback"));
  input Real vals_feedback_reference[nV,nFeedback]=fill(
      500 + 273.15,
      nV,
      nFeedback) "Reference value for reactivity feedback (e.g. fuel reference temperature)"
                                                 annotation (Dialog(tab="Kinetics",
        group="Inputs Reactivity Feedback"));
  // Initialization
  parameter SI.Power Qs_start[nV]=fill(Q_nominal/nV, nV)
    annotation (Dialog(tab="Initialization", enable=not specifyPower));

  // Advanced
  parameter Dynamics energyDynamics=Dynamics.DynamicFreeInitial annotation (
      Dialog(
      tab="Advanced",
      group="Dynamics",
      enable=not specifyPower));

  // Outputs
  output SI.Power Qs[nV](start=Qs_start) "Power determined from kinetics. Does not include fission product decay heat"
    annotation (Dialog(
      tab="Internal Inteface",
      group="Outputs",
      enable=false));
  output SIadd.ExtraPropertyFlowRate[nV,nI] mC_gens "Generation rate of precursor groups [atoms/s]"
    annotation (Dialog(
      tab="Internal Inteface",
      group="Outputs",
      enable=false));

  TRANSFORM.Units.NonDim[nV,nFeedback] rhos_feedback "Linear reactivity feedback";
  TRANSFORM.Units.NonDim[nV] rhos "Total reactivity feedback";

  input SI.Volume[nV] Vs "Volume for fisson product concentration basis" annotation(Dialog);

  Reactivity.FissionProducts_externalBalance_withTritium_withDecayHeat fissionProducts
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  replaceable record Data =
      TRANSFORM.Nuclear.ReactorKinetics.Data.FissionProducts.fissionProducts_0
    annotation (__Dymola_choicesAllMatching=true);
initial equation

  if not specifyPower then
    if energyDynamics == Dynamics.FixedInitial then
      Qs = Qs_start;
    elseif energyDynamics == Dynamics.SteadyStateInitial then
      der(Qs) = zeros(nV);
    end if;
  end if;

equation

  rhos_feedback = {{alphas_feedback[i,j]*(vals_feedback[i,j] - vals_feedback_reference[i,j]) for j in 1:nFeedback} for i in 1:nV};

  rhos = {sum(rhos_feedback[i,:]) +
    rhos_input[i] + sum(fissionProducts.rhos[i, :]) + sum(fissionProducts.rhos_TR[i, :]) for i in 1:nV};

  if specifyPower then
    Qs = Qs_input;
  else
    if energyDynamics == Dynamics.SteadyState then
      for i in 1:nV loop
        0 = (rhos[i] - Beta)/Lambda*Qs[i] + w_f/(Lambda*nu_bar)*sum(lambda_i .*
          mCs[i, :]) + w_f/(Lambda*nu_bar)*Ns_external[i];
      end for;
    else
      for i in 1:nV loop
        der(Qs[i]) = (rhos[i] - Beta)/Lambda*Qs[i] + w_f/(Lambda*nu_bar)*sum(
          lambda_i .* mCs[i, :]) + w_f/(Lambda*nu_bar)*Ns_external[i];
      end for;
    end if;
  end if;

  mC_gens = {{beta_i[j]*nu_bar/w_f*Qs[i] - lambda_i[j]*mCs[i, j] for j in 1:nI}
    for i in 1:nV};

  annotation (
    defaultComponentName="kinetics",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-100,-100},{100,100}},
          lineColor={0,0,127},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{28,-48.5},{40,-36.5}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Text(
          extent={{-149,138.5},{151,98.5}},
          textString="%name",
          lineColor={0,0,255}),
        Ellipse(
          extent={{-14,7},{-2,19}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-6,11},{6,23}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{2,7},{14,19}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{2,-1},{14,11}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-6,3},{6,15}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-6,-5},{6,7}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-14,-1},{-2,11}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-41.5,-41},{-29.5,-29}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-33,-49},{-21,-37}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-41.5,-49},{-29.5,-37}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{25.5,-39.5},{37.5,-27.5}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{19.5,-45},{31.5,-33}},
          fillColor={255,0,0},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{-6.5,55},{5.5,67}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Polygon(
          points={{-5.5,40},{-0.5,30},{4.5,40},{-5.5,40}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-1,50},{0,40}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Polygon(
          points={{-5,5},{0,-5},{5,5},{-5,5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-20,-23.5},
          rotation=-30),
        Rectangle(
          extent={{-0.5,5},{0.5,-5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-15,-15},
          rotation=-30),
        Polygon(
          points={{-5,5},{0,-5},{5,5},{-5,5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={20,-23.5},
          rotation=30),
        Rectangle(
          extent={{-0.5,5},{0.5,-5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={15,-15},
          rotation=30),
        Ellipse(
          extent={{-13.5,-66.5},{-1.5,-54.5}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{1,-61.5},{13,-49.5}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Polygon(
          points={{-5,5},{0,-5},{5,5},{-5,5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={33.5,61},
          rotation=90),
        Rectangle(
          extent={{-0.5,5},{0.5,-5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={23.5,61},
          rotation=90),
        Rectangle(
          extent={{-0.5,5},{0.5,-5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-34.5,61},
          rotation=90),
        Polygon(
          points={{-5,5},{0,-5},{5,5},{-5,5}},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0},
          origin={-24.5,61},
          rotation=90),
        Ellipse(
          extent={{-64.5,55},{-52.5,67}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Ellipse(
          extent={{53.5,55},{65.5,67}},
          fillColor={0,0,255},
          fillPattern=FillPattern.Sphere,
          pattern=LinePattern.None,
          lineColor={0,0,0})}),
    Diagram(coordinateSystem(preserveAspectRatio=false)));
end PointKinetics_Driftsfefe;