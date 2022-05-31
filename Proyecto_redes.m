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
colisiones_red=0;
paquete_recuperado=0;


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






% Inicio del ciclo
while ciclo < 50
%Generacion de paquetes cuando el ciclo sea 1 o t_arribo sea menor a t_sim

     while  t_arribo<t_sim ||ciclo==1
     tasa_paquetes=tasa_paquetes*N*I;    
     grado_aleatorio=randi([1 I],1,1) %Seleccionamos grado y nodo aleatorio
     nodo_aleatorio=randi([1 N],1,1)

     grado_seleccionado=Grados_red(grado_aleatorio); %Obtiene grado y nodo aleatorio de las clases creadas
     nodo_seleccionado=grado_seleccionado.nodos(nodo_aleatorio);

     espacio=false;
     lugar=0;

        for i=1:length(nodo_seleccionado.buffer)

        if nodo_seleccionado.buffer(i)==0  %Comprobacion de buffer si esta lleno o hay espacio
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

        if ciclo==1
        break;
        end

     end


    
      %t_arribo es mayor a t_sim, inicia el proceso de contención
        ranura_auxiliar=0;
        if ciclo==1
            for i=I:-1:1 %For para llenado de ranuras y que sea una trasmision consecutiva
           
            grado_actual=Grados_red(i);
            
    
            if ranura_auxiliar>0
            
            Ranuras=['S' Ranuras(1:20-1)]; %Para que siempre sea un tamaño 20
     
            end
            ranura_auxiliar=ranura_auxiliar+1;
            Grados_red(i).ranuras=Ranuras;
    
            
            end
        end
            

            if ciclo==1 || ranura>20 %Comienza la transmision desde la ranura 1
            ranura=1;
            end
            
        i=I;
        ranura_flag=true;
        transmision_exitosa=false;

        while transmision_exitosa==false

            while ranura_flag==true

            if Grados_red(i).ranuras(ranura) =='S'  %Comprobamos si la ranura actual es de sleep o no

                if i==1
                ranura=ranura+1;

                i=I;
                else
                i=i-1;    
                end

            elseif Grados_red(i).ranuras(ranura) =='T' % En caso de no ser ranura de sleep y es una transmision

                    nodos_transmisores=[];
        
                    for l=1:N %Verificacion de nodos y buffers que tengan paquetes que transmitir
                   
                    for t=1:K
                    if Grados_red(i).nodos(l).buffer(t)~=0
                    nodos_transmisores=[nodos_transmisores Grados_red(i).nodos(l).id];   
                    ranura_flag=false;
                    break
                  
                    end
                    end
                    end


                    if length(nodos_transmisores)==0
                    if i==1    
                    i=I;
                    else
                    i=i-1;
                    ranura=ranura+1;
                    end    
                    
                    
                    end
                 
                    


            else %No es transmision ni sleep
                if ranura==1
                
                ranura=ranura+1;
                else
                if i==1    
                i=I;
                else
                i=i-1;    
                end
                end
             
            end
            end

        %Proceso de contención

      

        contadores=[];
        nodos_contendientes=[];
        



        for l=1:length(nodos_transmisores)   %Asignamos una variable aleatoria a cada contador de cada nodo
        contador=randi([0 W-1],1,1);
        Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff=contador;
        contadores=[contadores Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff];
        
        end

        ganador=min(contadores); %Selecciona el ganador/es de el proceso de contención

            for k=1:N  %Busca si gano un solo nodo o varios
                if Grados_red(i).nodos(k).contador_backoff==ganador
                nodos_contendientes=[nodos_contendientes k]; %Variable que almacena el numero del nodo/nodos ganadores
                end

            end

        if length(nodos_contendientes)>1  %Si gano la contención mas de un nodo
        colisiones_red=colisiones_red+1;  %Aumenta numero de colisiones
        Grados_red(i).paquetes_colisionados=Grados_red(i).paquetes_colisionados+1;
        Grados_red(i).paquete_perdido_grado=Grados_red(i).paquete_perdido_grado+length(nodos_contendientes); %Aumenta perdidas de paquetes por grado y en la red
        paquetes_descartados=paquetes_descartados+length(nodos_contendientes);

            for n=1:length(nodos_contendientes)
            buffer_eliminado=Grados_red(i).nodos(n).buffer;   
                
            for b=1:K
            if buffer_eliminado(b)~=0 %Eliminamos el paquete del buffer de los nodos
               buffer_eliminado(b)=0;
               break
            end
            end
            Grados_red(i).nodos(n).buffer=buffer_eliminado;

            end
        t_sim=t_sim+T; 
        if i==1
        i=I;
        else
        i=i-1;
        end

        
        
        else  %En el caso de solo tener un nodo 

        transmision_exitosa=true;

        end
        end

        %Eliminamos paquete del buffer ganador
        
        buffer_eliminado=Grados_red(i).nodos(nodos_contendientes).buffer;
        for b=1:K
            if buffer_eliminado(b)~=0 %Eliminamos el paquete del buffer de los nodos
               paquete_recuperado=buffer_eliminado(b); 
               buffer_eliminado(b)=0;
               break
            end
        end
        buffer_recorrido=[];

        buffer_recorrido=[buffer_recorrido buffer_eliminado(2:K)];
        buffer_recorrido=[buffer_recorrido 0];
        Grados_red(i).nodos(nodos_contendientes).buffer=buffer_recorrido;

       
        %Comprobar si es grado 1 o cualquie otro
             if i==1  %Condicion que hace cuando es grado 1 y transmite a nodo sink
             
             paquetes_transmitidos=paquetes_transmitidos+1;
             Grados_red(i).paquete_transmitido_grado=Grados_red(i).paquete_transmitido_grado+1;
             t_sim=t_sim+T;
             t_sim=t_sim+T*[20-I];
             ranura=20;
             ciclo=ciclo+1;
             ranura=ranura+1;
             

        
             else 
                 
                 for t=1:K
                 if Grados_red(i-1).nodos(nodos_contendientes).buffer(t)==0
                 Grados_red(i-1).nodos(nodos_contendientes).buffer(t)=paquete_recuperado;
                 paquetes_transmitidos=paquetes_transmitidos+1;
                 break
                 else
                 paquetes_descartados=paquetes_descartados+1;
                 break
                 end
                 end 
             
             t_sim=t_sim+T;
             ciclo=ciclo+1;
             ranura=ranura+1;
             
             

             end



        end
 
        


        



     





    
     













