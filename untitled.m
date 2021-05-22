%% linprog
A = [-1, 1; 2, 3; 5, -1];
b = [ 5; 15; 10];
c = [3; 1];

x = linprog(-c, A, b, [], [], [0 0], [inf inf])
y = linprog(b, [], [], A', c, [0 0], [inf inf])

r1 = rank(A)
r2 = rank([A, b])

%% quadprog

A = [1 1; -1 1]
b = [10; 5]
c = [0; 2]
Q = eye(2)

x = quadprog(-0.5*Q, -c, A, b, [], [])

func = @(x) -x*Q*x' - c'*x'
x = fmincon(func, [0, 0], A, b)

x = -Q\b

%%
syms x
syms f(x)
g = f(x)^2