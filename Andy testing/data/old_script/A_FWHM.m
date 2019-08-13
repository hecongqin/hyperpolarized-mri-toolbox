% Andy's comment:
% 	This file is a modified version of A_generate_fitted_mat.m
%   This file is for Shuyu Tang to see FWHM of fitted Lac signal.

clear all;
close all;
clc;
% The data about FWHM
% max_lac=zeros(3,4,20);
% wid_lac=zeros(3,4,20);
max_lac=zeros(3,2,20);
wid_lac=zeros(3,2,20);
FWHM_ratio=0.3;
FWHM_step=7;
%%
data_dir = './Andy testing/Andy_data';
fitted_dir='./Andy testing/Andy_fitted';
tumors={'/786O','/A498','/uok262'};
tumors_num=length(tumors);
N = 20; % should double check with Renuka Sriram
fit_function = @fit_kPL;
line = 4; lac_sheet = 1; flip_sheet = 4;
plot_flag=0; plot_fits = 0; plot_mag = 0; load_avg=1; save_flag=0; disp_1xlsx_flag=0;


% picking data
thresh_above=3; % number of points above noise mean
noise_multiplyer=1.8; % multiplyer to the noise mean
%%
for tumor_counter=1:tumors_num % loop for one tumor folder
% tumor_counter=3;
    tumor_type=tumors(tumor_counter);
    tumor_type=char(tumor_type);
	[filenames,files_num] = A_get_filenames([data_dir,tumor_type]);
	filenames=char(filenames);
	tumor_kpl=zeros(6,files_num);
	errors=zeros(1,files_num);
	if mod(plot_flag,10)==3
		figure
	end

	% --------------------
	% load data;
	% --------------------
	for file_counter=1:files_num % loop for one xlsx file
		filename = filenames(file_counter,:);
		% filename='JW342_A498_122016_spspdyn copy.xlsx'
		filename=filename(1:strfind(filename, '.xlsx')-1);
		dir=[data_dir,tumor_type,'/',filename,'.xlsx'];
		if load_avg==1
			[flips,Mxy,t,TR,Tin,std_noise,mean_noise] = A_load_avg_data(dir,flip_sheet,N);
	    else
			[flips,Mxy,t,TR,std_noise] = A_load_vexel_data(dir,line,lac_sheet,flip_sheet,N);
	    end
	    % --------------------
		% Post process for input data
		% --------------------
	    std_noise=std_noise*sqrt(pi/2);
	    % first three flip is zero
	    Mxy=Mxy(:,4:end,:);
	    flips=flips(:,4:end);
	    t=t(4:end);
		% Test values;
		R1P = 1 / 25; R1L = 1 / 25; kPL = 0.05;
		input_function = zeros(1, N);

		mean_noise=ones(size(t))*mean_noise;
		use_flag=nnz(Mxy(1,:,1)>mean_noise*noise_multiplyer)>thresh_above;
		if use_flag==1
			use_flag=nnz(Mxy(1,:,2)>mean_noise*noise_multiplyer)>thresh_above;
		end
		% use_flag
		% --------------------
		% plot original data;
		% --------------------
		% plot flip angles;
		if plot_flag/10>=1
			figure
			subplot(221) , plot(t, squeeze(flips(1, : )) * 180 / pi)
			title('Pyruvate flips')
			subplot(222) , plot(t, squeeze(flips(2, : )) * 180 / pi,'o');
			hold on; plot(t, squeeze(flips(2, : )) * 180 / pi)
			title('Lactate flips')
			% plot pyr and lac
			subplot(2,2,3:4) , plot(t, squeeze(Mxy(1, : , 1)),'r')
			hold on
			plot(t, squeeze(Mxy(2, :,1 )),'r--')
			plot(t, squeeze(Mxy(1, :,2 )),'b')
			plot(t, squeeze(Mxy(2, :,2 )),'b--')
			plot(t, squeeze(Mxy(1, :,3 )),'g')
			plot(t, squeeze(Mxy(2, :,3 )),'g--')
			legend('Pyruvate tumor','Lactate tumor','Pyruvate control','Lactate control','Pyruvate noise','Lactate noise')
			title(['Mxy data',filename(1:10)])

		end
		if use_flag==1
			% initial parameter guesses;
			R1P_est = 1 / 25; R1L_est = 1 / 25; kPL_est = .02;
			% --------------------
			% Test fitting - fit kPL only;
			% --------------------
			if disp_1xlsx_flag==1
				disp('Fitting kPL, with fixed relaxation rates:')
			end
			
			% --------------------
			% Fitting with noise 1
			% --------------------

			clear params_fixed_1 params_est_1;
			clear params_fit1_t params_fit1_c params_fit1_n;
			clear sig_fit1_t sig_fit1_c sig_fit1_n;
			params_fixed_1.R1P = R1P_est; params_fixed_1.R1L = R1L_est;
			params_est_1.kPL = kPL_est;
			% fitting for tumor;
			[params_fit1_t(:) sig_fit1_t(1:size(Mxy, 2))] = fit_function(Mxy(:, :,1), TR, flips( :, :), params_fixed_1, params_est_1, std_noise, plot_fits);
			% fitting for control;
			[params_fit1_c(:) sig_fit1_c(1:size(Mxy, 2))] = fit_function(Mxy(:, :,2), TR, flips( :, :), params_fixed_1, params_est_1, std_noise, plot_fits);
			% fitting for noise;
			[params_fit1_n(:) sig_fit1_n(1:size(Mxy, 2))] = fit_function(Mxy(:, :,3), TR, flips( :, :), params_fixed_1, params_est_1, std_noise, plot_fits);
			
			% --------------------
			% Fitting without noise 2
			% --------------------
			clear params_fixed_2 params_est_2;
			clear params_fit2_t params_fit2_c params_fit2_n;
			clear sig_fit2_t sig_fit2_c sig_fit2_n;
			params_fixed_2.R1P = R1P_est; params_fixed_2.R1L = R1L_est;
			params_est_2.kPL = kPL_est;
			% fitting for tumor;
			[params_fit2_t(:) sig_fit2_t(1:size(Mxy, 2))] = fit_function(Mxy(:, :,1), TR, flips( :, :), params_fixed_2, params_est_2, [], plot_fits);
			% fitting for control;
			[params_fit2_c(:) sig_fit2_c(1:size(Mxy, 2))] = fit_function(Mxy(:, :,2), TR, flips( :, :), params_fixed_2, params_est_2, [], plot_fits);
			% fitting for noise;
			[params_fit2_n(:) sig_fit2_n(1:size(Mxy, 2))] = fit_function(Mxy(:, :,3), TR, flips( :, :), params_fixed_2, params_est_2, [], plot_fits);

			% max_lac(tumor_counter,:,file_counter)=[max(sig_fit1_t);max(sig_fit1_c);max(sig_fit2_t);max(sig_fit2_c)];
			% max_lac_temp=[max(sig_fit1_t);max(sig_fit1_c);max(sig_fit2_t);max(sig_fit2_c)];
			max_lac_temp=[max(Mxy(1,:,1));max(Mxy(1,:,2))];
			% index1=find(Mxy(1,:,1)>=max_lac_temp(1)*FWHM_ratio,1,'last');
			% index2=find(Mxy(1,:,2)>=max_lac_temp(2)*FWHM_ratio,1,'last');
			% index3=find(sig_fit2_t>=max_lac_temp(3)*FWHM_ratio,1,'last');
			% index4=find(sig_fit2_c>=max_lac_temp(4)*FWHM_ratio,1,'last');
			% wid_lac(tumor_counter,:,file_counter)=[index1;index2;index3;index4];
			index1=Mxy(1,FWHM_step,1)/max(Mxy(1,:,1));
			index2=Mxy(1,FWHM_step,2)/max(Mxy(1,:,2));
			wid_lac(tumor_counter,:,file_counter)=[index1;index2];
			
			if mod(plot_flag,10)==2
				figure
				subplot(121) , plot(t, squeeze(Mxy(1,:,1)),'b')
				hold on , plot(t, squeeze(Mxy(1,:,2)),'r')
				plot(t, squeeze(Mxy(1,:,3)),'g')
				legend('tumor','control','noise')
				title('Pyruvate signals')
				subplot(122) , plot(t, squeeze(Mxy(2,:,1)),'b')
				hold on, plot(t, squeeze(Mxy(2,:,2)),'r')
				plot(t, squeeze(Mxy(2,:,3)),'g')
				plot(t, squeeze(sig_fit1_t(:,:)),'bo')
				plot(t, squeeze(sig_fit1_c(:,:)),'ro')
				plot(t, squeeze(sig_fit1_n(:,:)),'go')

				plot(t, squeeze(sig_fit2_t(:,:)),'b*')
				plot(t, squeeze(sig_fit2_c(:,:)),'r*')
				plot(t, squeeze(sig_fit2_n(:,:)),'g*')
				title(['Lactate signals',filename(1:10)])
				legend('original tumor','original control','original noise',...
					'w-noise tumor','w-noise contorl','w-noise noise',...
					'wo-noise tumor','wo-noise contorl','wo-noise noise')

			end
			if mod(plot_flag,10)==3
					subplot(3,files_num,file_counter) , plot(t, squeeze(Mxy(1,:,1)),'b')
					hold on , plot(t, squeeze(Mxy(1,:,2)),'r')
					plot(t, squeeze(Mxy(1,:,3)),'g')
					legend('tumor','control','noise')
					title('Pyruvate signals')

					subplot(3,files_num,file_counter+files_num) , plot(t, squeeze(Mxy(2,:,1)),'b')
					hold on, plot(t, squeeze(Mxy(2,:,2)),'r')
					plot(t, squeeze(Mxy(2,:,3)),'g')
					plot(t, squeeze(sig_fit1_t(:,:)),'bo')
					plot(t, squeeze(sig_fit1_c(:,:)),'ro')
					plot(t, squeeze(sig_fit1_n(:,:)),'go')

					plot(t, squeeze(sig_fit2_t(:,:)),'b*')
					plot(t, squeeze(sig_fit2_c(:,:)),'r*')
					plot(t, squeeze(sig_fit2_n(:,:)),'g*')
					title(['Lactate signals',filename(1:10)])
					% legend('original tumor','original control','original noise',...
					% 	'w-noise tumor','w-noise contorl','w-noise noise',...
					% 	'wo-noise tumor','wo-noise contorl','wo-noise noise')

					subplot(3,files_num,file_counter+files_num*2) 
					plot(t, squeeze(Mxy(2,:,1))-squeeze(sig_fit1_t(:,:)),'b')
					% hold on, plot(t, squeeze(Mxy(2,:,2)),'r')
					% plot(t, squeeze(Mxy(2,:,3)),'g')
					% plot(t, squeeze(sig_fit1_t(:,:)),'bo')
					% plot(t, squeeze(sig_fit1_c(:,:)),'ro')
					% plot(t, squeeze(sig_fit1_n(:,:)),'go')

					% plot(t, squeeze(sig_fit2_t(:,:)),'b*')
					% plot(t, squeeze(sig_fit2_c(:,:)),'r*')
					% plot(t, squeeze(sig_fit2_n(:,:)),'g*')
					title(['Lactate error',filename(1:10)])
					% legend('original tumor','original control','original noise',...
					% 	'w-noise tumor','w-noise contorl','w-noise noise',...
					% 	'wo-noise tumor','wo-noise contorl','wo-noise noise')
			end
			% noise fitting
		    kpl_tmr_nf=struct2array(params_fit1_t).';
		    kpl_ctr_nf=struct2array(params_fit1_c).';
		    kpl_n_nf=struct2array(params_fit1_n).';
		    % without noise fitting
		    kpl_tmr_f=struct2array(params_fit2_t).';
		    kpl_ctr_f=struct2array(params_fit2_c).';
		    kpl_n_f=struct2array(params_fit2_n).';

		    tumor_kpl(:,file_counter)=[kpl_tmr_nf;kpl_ctr_nf;kpl_n_nf;...
	                                                kpl_tmr_f;kpl_ctr_f;kpl_n_f;];
			% % display
			% disp(['size of tumor_kpl: ',num2str(size(tumor_kpl))]);
		    sig_fit=[sig_fit1_t;sig_fit1_c;sig_fit1_n;
		    			sig_fit2_t;sig_fit2_c;sig_fit2_n];
			if save_flag==1
		 		save([fitted_dir,tumor_type,'/',filename],...
		 			'filename','Mxy','flips','sig_fit',...
		 			'kpl_tmr_nf','kpl_ctr_nf','kpl_n_nf',...
		 			'kpl_tmr_f','kpl_ctr_f','kpl_n_f')
		 	end
		 	errors(file_counter)= sqrt(mean((squeeze(Mxy(2,:,1))-squeeze(sig_fit1_t(:,:))).^2));
		end
	end % loop for one xlsx file
	tumor_kpl
	% save([fitted_dir,tumor_type],'tumor_type','tumor_kpl','errors')
end % loop for one tumor folder

%% plot
clc;
% size(wid_lac)=4,3,20
figure
for i=1:3
	subplot(1,3,i)
	a=squeeze(wid_lac(i,1,:));
	a=a(find(a));
	plot(a);
	hold on;
	a=squeeze(wid_lac(i,2,:));
	a=a(find(a));
	plot(a,'*--');
	legend([char(tumors(i)),' t'],[char(tumors(i)),' c'])
	ylim([0,1])
end
% for i=1:3
% 	subplot(2,3,i+3)
% 	a=squeeze(wid_lac(i,3,:));
% 	a=a(find(a));
% 	plot(a);
% 	hold on;
% 	a=squeeze(wid_lac(i,4,:));
% 	a=a(find(a));
% 	plot(a,'*--');
% 	ylim([0,17]);
% 	legend([char(tumors(i)),' t'],[char(tumors(i)),' c'])
% end