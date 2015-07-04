#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <stdlib.h>

/*** record for qsorting a graph to provide another isomorphic to it ***/
#define RecordSize 24
#define Undirected   0
#define Directed   1
#define MAX_COLS 3000
void print_graph( int v,
                  int e,
                  int* adj_matrix,
                  int dir_flag );
void random_connected_graph( int v,
                             int e,
                             int max_wgt,
                             int weight_flag
                             );
void permute( int* a, int n ); /* gives a random permutation */
void swap( int* a, int *b ); /* swap two ints */
void init_array( int* a, int end );
int ran( int k );     /* customized random number generator */
void DFS(int v,int n);
int stack[30];
FILE *fp1, *fp2;

//int n;
int map[30][30],visit[30];
void main(int argc, char **argv){
	int v;
	int e;
	int max_wgt;
	int weight_flag;
	char s[MAX_COLS];
	int start;
	int v1,v2;
	int dst;
	//char filename[5]={0};
	//strcpy(filename,argv[3]);
	random_connected_graph(atoi(argv[1]),atoi(argv[2]),1,2);
}

void DFS(int v, int n){
	FILE *fp3;
   

	if ( ( fp2 = fopen("./tmp/path", "a" ) ) == NULL ) {
		printf( "Unable to open file %s for writing.\n", "path" );
		return;
	}

	int i;
	visit[v] = 1;
	for(i=0;i<=n;i++){
		if(map[v][i] == 1 && !visit[i])
		{
			printf("%d %d\n",v,i);
			fprintf(fp2,"%d %d\n",v,i);
			//fprintf( fp, "%d %d \n", i, j);
			fclose(fp2);
			DFS(i,n);	
		}
	}
}
//void random_connected_graph( int v, int e,int max_wgt,int weight_flag,char* out_file )
void random_connected_graph( int v, int e,int max_wgt,int weight_flag )
{
   int i, j, count, index, *adj_matrix, *tree;

   if ( ( adj_matrix = ( int * ) calloc( v * v, sizeof( int ) ) )
        == NULL ) {
      printf( "Not enough room for this size graph\n" );
      return;
   }

   if ( ( tree = ( int * ) calloc( v, sizeof( int ) ) ) == NULL ) {
      printf( "Not enough room for this size graph\n" );
      free( adj_matrix );
      return;
   }

//   printf( "\n\tBeginning construction of graph.\n" );

   /*  Generate a random permutation in the array tree. */
   init_array( tree, v );
   permute( tree, v );

   /*  Next generate a random spanning tree.
       The algorithm is:

         Assume that vertices tree[ 0 ],...,tree[ i - 1 ] are in
         the tree.  Add an edge incident on tree[ i ]
         and a random vertex in the set {tree[ 0 ],...,tree[ i - 1 ]}.
    */

   for ( i = 1; i < v; i++ ) {
      j = ran( i );
      adj_matrix[ tree[ i ] * v + tree[ j ] ] =
         adj_matrix[ tree[ j ] * v + tree[ i ] ] =
         weight_flag ? 1 + ran( max_wgt ) : 1;
   }

   /* Add additional random edges until achieving at least desired number */

   for ( count = v - 1; count < e; ) {
      i = ran( v );
      j = ran( v );

      if ( i == j )
         continue;

      if ( i > j )
         swap( &i, &j );

      index = i * v + j;
      if ( !adj_matrix[ index ] ) {
         adj_matrix[ index ] = weight_flag ? 1 + ran( max_wgt ) : 1;
         count++;
      }
   }


   //print_graph( v, count, out_file, adj_matrix, Undirected );
   print_graph( v, count, adj_matrix, Undirected );

   free( tree );
   free( adj_matrix );
}
void permute( int* a, int n )
{
   int i;

   for ( i = 0; i < n - 1; i++ )
      swap( a + i + ran( n - i ), a + i );
}
void swap( int* a, int *b )
{
   int temp;

   temp = *a;
   *a = *b;
   *b = temp;
}
void init_array( int* a, int end )
{
   int i;

   for ( i = 0; i < end; i++ )
      *a++ = i;
}
int ran( int k )
{
   return rand() % k;
}
void print_graph( int v,
                  int e,
                  int* adj_matrix,
                  int dir_flag )
{
   int i, j, index;
   FILE *fp;
   
   if ( ( fp = fopen("./tmp/graph", "w" ) ) == NULL ) {
      printf( "Unable to open file %s for writing.\n", "graph" );
      return;
   }
//   printf( "\n\tWriting graph to file %s.\n", "graph" );

//   fprintf( fp, "%d %d\n", v, e );
   fprintf(fp,"%d\n",e+1);
   if ( !dir_flag )
      for ( i = 1; i < v; i++ )
         for ( j = i + 1; j <= v; j++ ) {
            index = ( i - 1 ) * v + j - 1;
            if ( adj_matrix[ index ] )
               //fprintf( fp, "%5d %5d   %5d\n", i, j, adj_matrix[ index ] );
               fprintf( fp, "%d %d %d\n", i, j, 1);
         }
   else
      for ( i = 1; i <= v; i++ )
         for ( j = 1; j <= v; j++ ) {
            index = ( i - 1 ) * v + j - 1;
            if ( adj_matrix[ index ] )
               //fprintf( fp, "%5d   %5d   %5d\n", i, j, adj_matrix[ index ] );
               fprintf( fp, "%d %d %d\n", i, j,1);
         }
   fclose( fp );
  // printf( "\tGraph is written to file %s.\n", out_file );
}

