// Data Reconciliation Benchmark Problems From Lietrature Review
// Author: Edson Cordeiro do Valle
// Contact - edsoncv@{gmail.com}{vrtech.com.br}
// Skype: edson.cv


clear xm var jac nc nv i1 i2 nnzeros sparse_dg sparse_dh lower upper var_lin_type constr_lin_type constr_lhs constr_rhs
getd('../');
getd('.');

run_new = 1;
// if you face problems with scilab 5.4, load a previoulsy saved result
if run_new == 1 then

    // run the steady_state_no_ge.zcos
    xcos('steady_state_no_ge.zcos');
    importXcosDiagram('steady_state_no_ge.zcos');
    scicos_simulate(scs_m);
    savematfile('-mat','ss_no_error_mat.sav', 'ss_sum_inlet', 'ss_outlet_tanks','ss_inlet_tanks','-v6');
else
    loadmatfile('-mat','ss_no_error_mat.sav', 'ss_sum_inlet', 'ss_outlet_tanks','ss_inlet_tanks','-v6');
    
end

wsize = 30;

filtered_out_sum_1 = moving(ss_outlet_tanks.values(:,1),wsize);
filtered_out_sum_2 = moving(ss_outlet_tanks.values(:,2),wsize);
filtered_out_sum_3 = moving(ss_outlet_tanks.values(:,3),wsize);
filtered_out_sum_4 = moving(ss_outlet_tanks.values(:,4),wsize);
filtered_in_sum_1 = moving(ss_sum_inlet.values,wsize);
filtered_in_sum_2 = moving(ss_inlet_tanks.values(:,1),wsize);
filtered_in_sum_3 = moving(ss_inlet_tanks.values(:,2),wsize);
filtered_in_sum_4 = moving(ss_inlet_tanks.values(:,3),wsize);

//load('rlt2.sav', 'filtered_out_sum_1','filtered_out_sum_2','filtered_out_sum_3','filtered_out_sum_4', 'filtered_in_sum_1','filtered_in_sum_2','filtered_in_sum_3','filtered_in_sum_4')
//
xm_full_unfiltered1 = [ss_sum_inlet.values, ss_inlet_tanks.values(:,1), ss_inlet_tanks.values(:,2), ss_inlet_tanks.values(:,3), ss_outlet_tanks.values(:,2), ss_outlet_tanks.values(:,3), ss_outlet_tanks.values(:,4), ss_outlet_tanks.values(:,1)];

xm_full_filtered1=[filtered_in_sum_1, filtered_in_sum_2, filtered_in_sum_3, filtered_in_sum_4,filtered_out_sum_2, filtered_out_sum_3, filtered_out_sum_4,  filtered_out_sum_1];

xm_full_filtered = xm_full_filtered1';
xm_full_unfiltered = xm_full_unfiltered1';

[xm_f_r, xm_f_col] = size(xm_full_filtered);
[xm_u_r, xm_u_col] = size(xm_full_unfiltered);

x_sol_filtered1 = zeros(xm_f_r, xm_f_col);
x_sol_unfiltered1 = zeros(xm_u_r, xm_u_col);
fsol_u = zeros(xm_u_r,1);
fsol_f = zeros(xm_f_r,1);
var = [0.5 0.5 0.3 1 0.25 0.5 1.5 1].^2;
var = var';
sigma=diag(var);
//The jacobian of the constraints
//      1   2   3   4   5   6   7   8    
jac = [ 1  -1  -1  -1   0   0   0   0   
        0   1   0   0  -1   0   0   0   
        0   0   1   0   0   -1  0   0   
        0   0   0   1   0   0  -1   0   
        0   0   0   0   1   1   1   -1   ];                                
//      1   2   3   4   5   6   7   8
umeas = [1 2 3 4];
[red, just_measured, observ, non_obs, spec_cand] = qrlinclass(jac,umeas);

// reconcile with all measured to reconcile with only redundant variables, uncomment the "red" assignments
measured = setdiff([1:size(xm_full_filtered(:,1),1)], umeas);
// to reconcile with all variables, uncomment bellow
//measured = [1:8];
nmeasured = length(measured);

[nc, nv, i1, i2, nnzeros, sparse_dg, sparse_dh, lower, upper, var_lin_type, constr_lin_type, constr_lhs, constr_rhs]  = wls_structurel(jac);

params = init_param();
// We use the given Hessian
params = add_param(params,"hessian_approximation","exact");
//params = add_param(params,"derivative_test","second-order");
params = add_param(params,"jac_c_constant","yes")
params = add_param(params,"hessian_constant","yes");
params = add_param(params,"tol",1e-6);
params = add_param(params,"acceptable_tol",1e-6);
params = add_param(params,"mu_strategy","adaptive");
params = add_param(params,"linear_solver","mumps");
params = add_param(params,"journal_level",4);

// unfiltered data
for i=1:xm_f_col
//for i=1:10
    disp(i);
    xm = xm_full_unfiltered(:,i);
    [x_sol_unfiltered1(:,i), f_sol(i), extra] = ipopt(xm, objfun, gradf, confun, dg, sparse_dg, dh, sparse_dh, var_lin_type, constr_lin_type, constr_rhs, constr_lhs, lower, upper, params);
end
// filtered data
//for i=1:10
for i=1:xm_u_col
    disp(i);
    xm = xm_full_filtered(:,i);
    [x_sol_filtered1(:,i), f_sol(i), extra] = ipopt(xm, objfun, gradf, confun, dg, sparse_dg, dh, sparse_dh, var_lin_type, constr_lin_type, constr_rhs, constr_lhs, lower, upper, params);
end
//

x_sol_filtered = x_sol_filtered1';
x_sol_unfiltered = x_sol_unfiltered1';


use_subplot = 0;
if use_subplot == 1 then

    i=0;
    j=0;
    dx=800;
    dy=445;
    vsize=800;
    hsize=800

    a1=scf(1);
    subplot(2,2,1);
    set(a1,"figure_size",[vsize,hsize]);
    set(a1,"figure_position",[i*dx,j*dy]);
    //i=i+1;
    plot(ss_outlet_tanks.time,xm_full_filtered(1,:)','r', ss_outlet_tanks.time,x_sol_filtered1(1,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(1,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(1,:)','yel');
    title("m =" + string(wsize) + " - Input - Stream 1");
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",4);
    subplot(2,2,2);
    title('m =' + string(wsize) + ' - Tank 1 Input - Stream 2');
    plot(ss_outlet_tanks.time,xm_full_filtered(2,:)','r', ss_outlet_tanks.time,x_sol_filtered1(2,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(2,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(2,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);
    subplot(2,2,3);
    title('m =' + string(wsize) + ' - Tank 2 Input - Stream 3');
    plot(ss_outlet_tanks.time,xm_full_filtered(3,:)','r', ss_outlet_tanks.time,x_sol_filtered1(3,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(3,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(3,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);
    subplot(2,2,4);
    title('m =' + string(wsize) + ' - By-pass Input - Stream 4')
    plot(ss_outlet_tanks.time,xm_full_filtered(4,:)','r', ss_outlet_tanks.time,x_sol_filtered1(4,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(4,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(4,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",2);    

    i=i+1
    a2=scf(2);

    subplot(2,2,1);
    set(a2,"figure_size",[vsize,hsize]);
    set(a2,"figure_position",[i*dx,j*dy]);
    title('m =' + string(wsize) + ' - Tank 1 Output - Stream 5');
    plot(ss_outlet_tanks.time,xm_full_filtered(5,:)','r', ss_outlet_tanks.time,x_sol_filtered1(5,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(5,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(5,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);
    subplot(2,2,2);
    title('m =' + string(wsize) + ' - Tank 2 Output - Stream 6');
    plot(ss_outlet_tanks.time,xm_full_filtered(6,:)','r', ss_outlet_tanks.time,x_sol_filtered1(6,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(6,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(6,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);        
    subplot(2,2,3);
    title('m =' + string(wsize) + ' - By-pass Input - Stream 7');
    plot(ss_outlet_tanks.time,xm_full_filtered(7,:)','r', ss_outlet_tanks.time,x_sol_filtered1(7,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(7,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(7,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",2);        
    subplot(2,2,4);
    title('m =' + string(wsize) + ' - Outnput - Stream 8');
    plot(ss_outlet_tanks.time,xm_full_filtered(8,:)','r', ss_outlet_tanks.time,x_sol_filtered1(8,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(8,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(8,:)','yel');
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",4);
    // IF USER FACE PROBLEMS WITH THE SUBPLOT FUNCTION (SUCH AS SCILAB CRASH) IT IS POSSIBLE TO ANALYSE THE CHARTS INDIVIDUALLY, IN THIS CASE, COMMENT THE LINES ABOVE AND UNCOMMENT BELLOW
else

    //
    i=0;
    j=0;
    dx=400;
    dy=445;
    vsize=400;
    hsize=440

    a3=scf(3);

    set(a3,"figure_size",[vsize,hsize]);
    set(a3,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 2");
    plot(ss_outlet_tanks.time,xm_full_filtered(1,:)','r', ss_outlet_tanks.time,x_sol_filtered1(1,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(1,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(1,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",4);

    a4=scf(4);
    set(a4,"figure_size",[vsize,hsize]);
    set(a4,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 3");
    plot(ss_outlet_tanks.time,xm_full_filtered(2,:)','r', ss_outlet_tanks.time,x_sol_filtered1(2,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(2,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(2,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);

    a5=scf(5);
    set(a5,"figure_size",[vsize,hsize]);
    set(a5,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 4");    
    plot(ss_outlet_tanks.time,xm_full_filtered(3,:)','r', ss_outlet_tanks.time,x_sol_filtered1(3,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(3,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(3,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);

    a6=scf(6);
    set(a6,"figure_size",[vsize,hsize]);
    set(a6,"figure_position",[i*dx,j*dy]);
    i=0;
    j=j+1;
    title("m =" + string(wsize) + " - Input - Stream 5");    
    plot(ss_outlet_tanks.time,xm_full_filtered(4,:)','r', ss_outlet_tanks.time,x_sol_filtered1(4,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(4,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(4,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",2);    

    a7=scf(7);
    set(a7,"figure_size",[vsize,hsize]);
    set(a7,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 6");    
    plot(ss_outlet_tanks.time,xm_full_filtered(5,:)','r', ss_outlet_tanks.time,x_sol_filtered1(5,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(5,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(5,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);

    a8=scf(8);
    set(a8,"figure_size",[vsize,hsize]);
    set(a8,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 7");    
    plot(ss_outlet_tanks.time,xm_full_filtered(6,:)','r', ss_outlet_tanks.time,x_sol_filtered1(6,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(6,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(6,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",1);

    a9=scf(9);
    set(a9,"figure_size",[vsize,hsize]);
    set(a9,"figure_position",[i*dx,j*dy]);
    i=i+1;
    title("m =" + string(wsize) + " - Input - Stream 8");    
    plot(ss_outlet_tanks.time,xm_full_filtered(7,:)','r', ss_outlet_tanks.time,x_sol_filtered1(7,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(7,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(7,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",2);

    a10=scf(10);
    set(a10,"figure_size",[vsize,hsize]);
    set(a10,"figure_position",[i*dx,j*dy]);
    plot(ss_outlet_tanks.time,xm_full_filtered(8,:)','r', ss_outlet_tanks.time,x_sol_filtered1(8,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(8,:)','g', ss_outlet_tanks.time,x_sol_unfiltered1(8,:)','yel')
    legend("meas_filtered", "reconc_filtered", "meas_unfiltered", "reconc_unfiltered",4);
end
//
//














//i=0;
//j=0;
//dx=800;
//dy=445;
//vsize=800;
//hsize=900
//
//a3=scf();
//subplot(2,2,1);
//set(a3,"figure_size",[vsize,hsize]);
//set(a3,"figure_position",[i*dx,j*dy]);
//plot(ss_outlet_tanks.time,xm_full_filtered(1,:)','r', ss_outlet_tanks.time,x_sol_filtered(1,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(1,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(1,:)','yel')
//title("m =" + string(wsize) + " - Input - Stream 1");
//subplot(2,2,2);
//title('Unmeasured - m =' + string(wsize) + ' - Tank 1 Input - Stream 2');
//plot(ss_outlet_tanks.time,xm_full_filtered(2,:)','r', ss_outlet_tanks.time,x_sol_filtered(2,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(2,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(2,:)','yel')
//subplot(2,2,3);
//title('Unmeasured - m =' + string(wsize) + ' - Tank 2 Input - Stream 3');
//plot(ss_outlet_tanks.time,xm_full_filtered(3,:)','r', ss_outlet_tanks.time,x_sol_filtered(3,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(3,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(3,:)','yel')
//subplot(2,2,4);
//title('Unmeasured - m =' + string(wsize) + ' - By-pass Input - Stream 4');
//plot(ss_outlet_tanks.time,xm_full_filtered(4,:)','r', ss_outlet_tanks.time,x_sol_filtered(4,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(4,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(4,:)','yel')
//i=i+1;
//a4=scf();
//subplot(2,2,1);
//set(a4,"figure_size",[vsize,hsize]);
//set(a4,"figure_position",[i*dx,j*dy]);
//title('m =' + string(wsize) + ' - Tank 1 Output - Stream 5');
//plot(ss_outlet_tanks.time,xm_full_filtered(5,:)','r', ss_outlet_tanks.time,x_sol_filtered(5,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(5,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(5,:)','yel')
//subplot(2,2,2)
//title('m =' + string(wsize) + ' - Tank 2 Output - Stream 6');
//plot(ss_outlet_tanks.time,xm_full_filtered(6,:)','r', ss_outlet_tanks.time,x_sol_filtered(6,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(6,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(6,:)','yel')
//subplot(2,2,3)
//title('m =' + string(wsize) + ' - By-pass Input - Stream 7');
//plot(ss_outlet_tanks.time,xm_full_filtered(7,:)','r', ss_outlet_tanks.time,x_sol_filtered(7,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(7,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(7,:)','yel')
//subplot(2,2,4)
//title('m =' + string(wsize) + ' - Outnput - Stream 8');
//plot(ss_outlet_tanks.time,xm_full_filtered(8,:)','r', ss_outlet_tanks.time,x_sol_filtered(8,:)','blu',ss_outlet_tanks.time,xm_full_unfiltered(8,:)','g', ss_outlet_tanks.time,x_sol_unfiltered(8,:)','yel')
//
