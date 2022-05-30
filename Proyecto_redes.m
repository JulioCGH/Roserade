clear all;
close all;
clc;

%Variables del programa
I=7;
K=15;
ranura_sleep=18;
DIFS=10e-3;
SIFS=5e-3;
durRTS=11e-3;
durCTS=11e-3;
durACK=11e-3;
durDATA=43e-3;
dur_miniranura=1e-3;
t_sim=0;
W=16;
N=5;
tasa_paquetes=0.0005;
T=durDATA+durRTS+durCTS+DIFS+durACK+dur_miniranura*W+3*SIFS;
Tc=T*(ranura_sleep+2);
ciclo=1;
paquetes_descartados=0;
paquetes_transmitidos=0;
ranura=1;



%Generacion de tiempo de arribo
u=(1e6*rand)/1e6;
nuevo_tiempo=-(1/tasa_paquetes)*log(1-u);
t_arribo=t_sim+nuevo_tiempo;


%Generamos los grados y nodos

grados=Grado;
nodos=Nodo;
buffer=zeros(1,K);

Ranuras=['R' 'T' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S'];

for i=1:I
grados.id=i;
grados.ranuras=Ranuras;
Grados_red(i)=grados;

for j=1:N
nodos.id=j;
nodos.buffer=buffer(1,:);
Nodos_grado(j)=nodos;
end
Grados_red(i).nodos=Nodos_grado;

end





t_arribo=1;
ciclo=2;
% Inicio del ciclo
% while ciclo < 2

%Generacion de paquetes cuando el ciclo sea 1 o t_arribo sea menor a t_sim
     if ciclo==1 || t_arribo<t_sim
     grado_aleatorio=randi([1 I],1,1); %Seleccionamos grado y nodo aleatorio
     nodo_aleatorio=randi([1 N],1,1);

     grado_seleccionado=Grados_red(grado_aleatorio); %Obtiene grado y nodo aleatorio de las clases creadas
     nodo_seleccionado=grado_seleccionado.nodos(nodo_aleatorio);

     espacio=false;
     lugar=0;

        for i=1:length(nodo_seleccionado.buffer)

        if nodo_seleccionado.buffer(i)==0  %Comp´robacion de buffer si esta lleno o hay espacio
        espacio=true;
        lugar=i;
        break
        end
     
        end

        if espacio==true  %Si hay espacio, asigna paquete a grado y nodo aleatorio

        nodo_seleccionado.buffer(lugar)=1;
        Grados_red(grado_aleatorio).nodos(nodo_aleatorio)=nodo_seleccionado;
        u=(1e6*rand)/1e6;
        nuevo_tiempo=-(1/tasa_paquetes)*log(1-u);
        t_arribo=t_sim+nuevo_tiempo; %Generamos nuevo t_arribo
   
        else %No hay espacio, se descarta el paquete

        paquetes_descartados=paquetes_descartados+1;
        Grados_red(grado_aleatorio).paquete_perdido_grado=Grados_red(grado_aleatorio).paquete_perdido_grado+1;
        u=(1e6*rand)/1e6;
        nuevo_tiempo=-(1/tasa_paquetes)*log(1-u);
        t_arribo=t_sim+nuevo_tiempo; %Se genera un nuevo t_arribo
        end


    
     else %t_arribo es mayor a t_sim, inicia el proceso de contención
     ranura_auxiliar=0;

        for j=7:-1:1 %For para llenado de ranuras y que sea una trasmision consecutiva
       
        grado_actual=Grados_red(j);
        

        if ranura_auxiliar>0
        
        Ranuras=['S' Ranuras(1:20-1)]; %Para que siempre sea un tamaño 20
 
        end
        ranura_auxiliar=ranura_auxiliar+1;
        Grados_red(j).ranuras=Ranuras;

        ranura_flag=true;
        
            

            if ciclo==1 || ranura>20 %Comienza la transmision desde la ranura 1
            ranura=1;
            else %En caso de que aun no se recorran todas las ranuras
            ranura=ranura;
            end
            i=I;


            while ranura_flag==true

            if Grados_red(i).ranuras(ranura) =='S'  %Comprobamos si la ranura actual es de sleep o no

                if i==1
                ranura=ranura+1;

                i=I;
                else
                i=i+1;    
                end

            elseif Grados_red(i).ranuras(ranura) =='T' % En caso de no ser ranura de sleep y es una transmision
            ranura_flag=false;
            else %No es transmision ni sleep
                if ranura==1
                ranura=ranura+1;
                else
                i=i+1;
                end
             
            end
            end

          
            
       



        end

        end
     
        





% end






