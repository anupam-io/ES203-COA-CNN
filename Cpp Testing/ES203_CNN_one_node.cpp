#include "bits/stdc++.h"
using namespace std;

int max_value = 25;
int alpha = 1;
int th = 2;

long double adv_relu(long double x)
{
	if (x >= max_value)
		return max_value;
	else if (x <= th)
		return alpha * (x - th);
	else
		return x;
}

int main()
{
	ofstream fout;
	fout.open("All_Outputs.txt");

	int n_of_filters = 1, obj = 10, test_images = 50000;

	int R = 32, C = 32, R_M = 30, C_M = 30; // Dimensions of image and convolution outputs
	int Right = 0, Wrong = 0;

	int m, var, it, i, j, k, t, r; // General Purpose Iterators

	int Image[1024];
	long double Filters[n_of_filters * 10]; // 8byte containers providing 33 to 36 significant digits
	long double K1, K2, K3, K4, K5, K6, K7, K8, K9, fb;
	long double Conv[(R - 2) * (C - 2)];
	long double MP[225];
	long double Flat_Layer[225 * n_of_filters];

	long double Weights[225 * obj];
	long double Bias[obj];
	long double Final[obj];

	long double temp, sum;

	ifstream in, image_in, label_in;
	in.open("WEIGHTS.txt");
	for (i = 0; i < 2250; i++)
	{
		in >> Weights[i];
	}
	in.close();

	in.open("BIAS.txt");
	for (i = 0; i < obj; i++)
	{
		in >> Bias[i];
	}
	in.close();

	in.open("FILTERS.txt");
	for (i = 0; i < n_of_filters * obj; i++)
	{
		in >> Filters[i];
	}
	in.close();

	label_in.open("LABELS.txt");

	image_in.open("RAW_IMAGES.txt");
	for (int x = 0; x < test_images; x++)
	{
		for (i = 0; i < 1024; i++)
		{
			image_in >> Image[i];
		}

		for (t = 0; t < n_of_filters; t++)
		{

			K1 = Filters[10 * t + 0];
			K2 = Filters[10 * t + 1];
			K3 = Filters[10 * t + 2];
			K4 = Filters[10 * t + 3];
			K5 = Filters[10 * t + 4];
			K6 = Filters[10 * t + 5];
			K7 = Filters[10 * t + 6];
			K8 = Filters[10 * t + 7];
			K9 = Filters[10 * t + 8];
			fb = Filters[10 * t + 9];

			for (it = 0, r = 0; r <= 29; r = r + 1)
			{
				for (i = r * C, j = (r + 1) * C, k = (r + 2) * C; i <= (r + 1) * C - 3; i = i + 1, j = j + 1, k = k + 1, it = it + 1)
				{
					Conv[it] = K1 * Image[i] + K2 * Image[i + 1] + K3 * Image[i + 2] + K4 * Image[j] + K5 * Image[j + 1] + K6 * Image[j + 2] + K7 * Image[k] + K8 * Image[k + 1] + K9 * Image[k + 2];
					Conv[it] += fb;
				}
			}

			for (it = 0, r = 0; r <= 28; r = r + 2)
			{
				for (i = r * R_M, j = (r * R_M) + C_M; i <= (r + 1) * C_M - 2; i = i + 2, j = j + 2)
				{
					temp = Conv[i];
					if (Conv[i + 1] > temp)
						temp = Conv[i + 1];
					if (Conv[j] > temp)
						temp = Conv[j];
					if (Conv[j + 1] > temp)
						temp = Conv[j + 1];

					MP[it] = adv_relu(temp);
					it = it + 1;
				}
			}

			for (i = 0; i < 225; i++)
			{
				Flat_Layer[225 * t + i] = MP[i];
			}
		}

		//Output Layer
		for (t = 0; t < obj; t++)
		{
			temp = 0;
			for (j = 0; j < 225; j++)
			{
				temp += (Weights[225 * t + j] * Flat_Layer[j]);
			}
			Final[t] = temp + Bias[t];
		}

		for (m = 0, i = 1; i < 10; i++)
			if (Final[i] > Final[m])
				m = i;

		label_in >> var;

		if (var == m)
			Right++;
		else
			Wrong++;

		//////////-------------------Printing----------------------/////////////////
		fout << "\n\n\n";
		fout << "---------------------------------------------IMAGE" << x + 1 << "---------------------------------------------------";
		fout << "\n__IMAGE__\n";
		for (int i = 0; i < C; i++)
		{
			for (int j = 0; j < R; j++)
			{
				fout << Image[C * i + j] << " ";
			}
			fout << endl;
		}

		fout << "\n__CONVOLUTION__\n";
		for (int i = 0; i < C_M; i++)
		{
			for (int j = 0; j < C_M; j++)
			{
				fout << Conv[C_M * i + j] << " ";
			}
			fout << endl;
		}

		fout << "\n__MAX POOLING_&_FLAT_LAYER__\n";
		for (int i = 0; i < 225; i++)
		{
			fout << MP[i] << " ";
			if ((i + 1) % 15 == 0)
				fout << endl;
		}

		fout << "\nFINAL_OUTPUT_RESULT\n";
		for (int i = 0; i < obj; i++)
		{
			if (m == i)
				fout << "{" << Final[i] << "}"
						 << " ";
			else
				fout << Final[i] << " ";
		}
		fout << "\n******************************************************************************************************************\n";
	}

	fout << "Right " << Right << endl
			 << "Wrong " << Wrong << endl;
	cout << "Right " << Right << endl
			 << "Wrong " << Wrong << endl;

	in.close();
	image_in.close();
	fout.close();
	label_in.close();
	return 0;
}
